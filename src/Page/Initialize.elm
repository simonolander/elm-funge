module Page.Initialize exposing
    ( Model
    , Msg
    , init
    , load
    , subscriptions
    , update
    , view
    )

import Api.Auth0 as Auth0
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Browser.Navigation
import Data.AccessToken as AccessToken exposing (AccessToken)
import Data.Cache as Cache exposing (Cache)
import Data.DetailedHttpError as DetailedHttpError exposing (DetailedHttpError)
import Data.Draft as Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId exposing (DraftId)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache exposing (RemoteCache)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Data.User as User
import Data.UserInfo as UserInfo exposing (UserInfo)
import Dict exposing (Dict)
import Element exposing (..)
import Element.Font as Font
import Element.Input as Input
import Extra.Cmd exposing (noCmd, withCmd)
import Extra.Result
import Json.Decode as Decode
import Json.Encode as Encode
import Levels
import Maybe.Extra
import Ports.Console
import RemoteData
import Route exposing (Route)
import Url
import View.Constant exposing (color)
import View.ErrorScreen
import View.Layout
import View.LoadingScreen
import ViewComponents



-- MODEL


type ConflictResolution a
    = DoNothing
    | KeepLocal a
    | KeepActual a
    | ResolveManually
        { local : a
        , expected : Maybe a
        , actual : a
        }
    | Error DetailedHttpError


type InitializationError
    = NetworkMissing
    | ServerError DetailedHttpError


type Saving a
    = Saving a
    | Saved (Result DetailedHttpError a)


type AccessTokenState
    = Missing
    | Expired AccessToken
    | Verifying AccessToken
    | Verified
        { accessToken : AccessToken
        , userInfo : UserInfo
        }


type alias Model =
    { session : Session
    , route : Route
    , accessTokenState : AccessTokenState
    , expectedUserInfo : Maybe UserInfo
    , actualUserInfo : RemoteData.RemoteData DetailedHttpError UserInfo
    , localDrafts : Dict DraftId (Result Decode.Error Draft)
    , localDraftBooks : Dict LevelId (Result Decode.Error DraftBook)
    , expectedDrafts : Dict DraftId (Result Decode.Error Draft)
    , actualDrafts : Cache DraftId Draft
    , savingDrafts : Dict DraftId (Saving Draft)
    , error : Maybe InitializationError
    }


type Msg
    = GotUserInfoResponse (Result DetailedHttpError UserInfo)
    | GotDraftLoadResponse (RequestResult DraftId DetailedHttpError Draft)
    | GotDraftSaveResponse (RequestResult Draft DetailedHttpError ())
    | ClickedContinueOffline
    | ClickedDraftKeepLocal DraftId
    | ClickedDraftKeepServer DraftId
    | ClickedImportLocalData
    | ClickedDeleteLocalData
    | ClickedSignInToOtherAccount


init :
    { navigationKey : Browser.Navigation.Key
    , localStorageEntries : List ( String, Encode.Value )
    , url : Url.Url
    }
    -> ( Model, Cmd Msg )
init { navigationKey, localStorageEntries, url } =
    let
        ( route, accessToken, accessTokenCmd ) =
            case Auth0.loginResponseFromUrl url of
                Just loginResponse ->
                    ( loginResponse.route
                    , Just loginResponse.accessToken
                    , Cmd.none
                    )

                Nothing ->
                    let
                        accessTokenResult =
                            localStorageEntries
                                |> List.filterMap AccessToken.localStorageResponse
                                |> List.head
                                |> Maybe.map .result
                    in
                    ( Route.fromUrl url
                        |> Maybe.withDefault Route.Home
                    , accessTokenResult
                        |> Maybe.andThen Result.toMaybe
                        |> Maybe.Extra.join
                    , case accessTokenResult of
                        Just (Err error) ->
                            Ports.Console.errorString (Decode.errorToString error)

                        _ ->
                            Cmd.none
                    )

        expectedUserInfoResult =
            localStorageEntries
                |> List.filterMap UserInfo.localStorageResponse
                |> List.head
                |> Maybe.andThen RequestResult.extractMaybe
                |> Maybe.map .result

        localDrafts =
            localStorageEntries
                |> List.filterMap Draft.localStorageResponse
                |> List.filterMap RequestResult.extractMaybe
                |> List.map RequestResult.toTuple
                |> Dict.fromList

        expectedDrafts =
            localStorageEntries
                |> List.filterMap Draft.localRemoteStorageResponse
                |> List.filterMap RequestResult.extractMaybe
                |> List.map RequestResult.toTuple
                |> Dict.fromList

        localDraftBooks =
            localStorageEntries
                |> List.filterMap DraftBook.localStorageResponse
                |> List.map RequestResult.toTuple
                |> Dict.fromList

        model =
            { session =
                Session.init navigationKey url
                    |> Levels.withTestLevels
            , route = route
            , accessTokenState =
                accessToken
                    |> Maybe.map Verifying
                    |> Maybe.withDefault Missing
            , expectedUserInfo = Maybe.andThen Result.toMaybe expectedUserInfoResult
            , actualUserInfo = RemoteData.NotAsked
            , localDrafts = localDrafts
            , expectedDrafts = expectedDrafts
            , actualDrafts = Cache.empty
            , savingDrafts = Dict.empty
            , localDraftBooks = localDraftBooks
            , error = Nothing
            }

        cmd =
            Cmd.batch
                [ accessTokenCmd
                , expectedUserInfoResult
                    |> Maybe.andThen Extra.Result.getError
                    |> Maybe.map Decode.errorToString
                    |> Maybe.map Ports.Console.errorString
                    |> Maybe.withDefault Cmd.none
                ]
    in
    ( model, cmd )


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadUserData model =
            case ( model.accessTokenState, model.actualUserInfo ) of
                ( Verifying accessToken, RemoteData.NotAsked ) ->
                    ( { model
                        | actualUserInfo = RemoteData.Loading
                      }
                    , Cmd.batch
                        [ UserInfo.loadFromServer accessToken GotUserInfoResponse
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        loadDrafts model =
            case model.accessTokenState of
                Verified { accessToken } ->
                    let
                        loadingDraftIds =
                            model.localDrafts
                                |> Dict.toList
                                |> List.filterMap
                                    (\( draftId, localDraftResult ) ->
                                        if RemoteData.isNotAsked (Cache.get draftId model.actualDrafts) then
                                            case ( localDraftResult, Dict.get draftId model.expectedDrafts ) of
                                                ( Ok localDraft, Just (Ok expectedDraft) ) ->
                                                    if Draft.eq localDraft expectedDraft then
                                                        Nothing

                                                    else
                                                        Just draftId

                                                _ ->
                                                    Just draftId

                                        else
                                            Nothing
                                    )
                    in
                    ( loadingDraftIds
                        |> List.foldl Cache.loading model.actualDrafts
                        |> flip withActualDrafts model
                    , Cmd.batch
                        [ loadingDraftIds
                            |> List.map (Draft.loadFromServer accessToken GotDraftLoadResponse)
                            |> Cmd.batch
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        finish model =
            case model.accessTokenState of
                Missing ->
                    let
                        user =
                            model.session.user
                                |> User.withUserInfo model.expectedUserInfo

                        session =
                            model.session
                                |> Session.withUser user
                    in
                    ( { model | session = session }
                    , Route.replaceUrl model.session.key model.route
                    )

                Expired _ ->
                    ( model, Cmd.none )

                Verifying _ ->
                    ( model, Cmd.none )

                Verified { accessToken, userInfo } ->
                    let
                        hasDraftConflicts =
                            Dict.keys model.localDrafts
                                |> List.map (\draftId -> ( Dict.get draftId model.localDrafts, Dict.get draftId model.expectedDrafts ))
                                |> List.filter (\( local, expected ) -> local /= expected)
                                |> List.isEmpty
                                |> not
                    in
                    if hasDraftConflicts then
                        ( model, Cmd.none )

                    else
                        let
                            user =
                                User.authorizedUser accessToken userInfo

                            draftCache : RemoteCache DraftId Draft
                            draftCache =
                                { local =
                                    model.localDrafts
                                        |> Dict.map (always (Result.mapError RequestResult.badBody))
                                        |> Cache.fromResultDict
                                , expected =
                                    model.expectedDrafts
                                        |> Dict.map (always (Result.mapError RequestResult.badBody))
                                        |> Cache.fromResultDict
                                , actual = model.actualDrafts
                                }

                            session =
                                model.session
                                    |> Session.withUser user
                                    |> Session.withDraftCache draftCache

                            saveDraftsLocallyCmd =
                                Cmd.batch
                                    [ model.localDrafts
                                        |> Dict.values
                                        |> List.filterMap Result.toMaybe
                                        |> List.map Draft.saveToLocalStorage
                                        |> Cmd.batch
                                    , model.actualDrafts
                                        |> Cache.values
                                        |> List.filterMap RemoteData.toMaybe
                                        |> List.map Draft.saveRemoteToLocalStorage
                                        |> Cmd.batch
                                    ]
                        in
                        ( { model | session = session }
                        , Cmd.batch
                            [ AccessToken.saveToLocalStorage accessToken
                            , UserInfo.saveToLocalStorage userInfo
                            , saveDraftsLocallyCmd
                            , Route.replaceUrl model.session.key model.route
                            ]
                        )
    in
    Extra.Cmd.fold
        [ loadUserData
        , loadDrafts
        , finish
        ]


withSession : Session -> Model -> Model
withSession session model =
    { model | session = session }


withError : DetailedHttpError -> Model -> Model
withError error model =
    { model
        | error =
            case error of
                DetailedHttpError.NetworkError ->
                    Just NetworkMissing

                _ ->
                    Just (ServerError error)
    }


withSavingDraft : Draft -> Model -> Model
withSavingDraft draft model =
    { model | savingDrafts = Dict.insert draft.id (Saving draft) model.savingDrafts }


withSavedDraft : RequestResult Draft DetailedHttpError any -> Model -> Model
withSavedDraft { request, result } model =
    case result of
        Ok _ ->
            { model | savingDrafts = Dict.insert request.id (Saved (Ok request)) model.savingDrafts }

        Err error ->
            { model | savingDrafts = Dict.insert request.id (Saved (Err error)) model.savingDrafts }


withActualDrafts : Cache DraftId Draft -> Model -> Model
withActualDrafts actualDrafts model =
    { model | actualDrafts = actualDrafts }


withExpiredAccessToken : Model -> Model
withExpiredAccessToken model =
    { model
        | accessTokenState =
            case model.accessTokenState of
                Missing ->
                    Missing

                Expired accessToken ->
                    Expired accessToken

                Verifying accessToken ->
                    Expired accessToken

                Verified { accessToken } ->
                    Expired accessToken
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUserInfoResponse result ->
            let
                modelWithActualUserInfo =
                    { model | actualUserInfo = RemoteData.fromResult result }
            in
            case result of
                Ok actualUserInfo ->
                    let
                        verified =
                            case modelWithActualUserInfo.accessTokenState of
                                Verifying accessToken ->
                                    Verified
                                        { accessToken = accessToken
                                        , userInfo = actualUserInfo
                                        }

                                _ ->
                                    modelWithActualUserInfo.accessTokenState
                    in
                    case modelWithActualUserInfo.expectedUserInfo of
                        Just expectedUserInfo ->
                            if expectedUserInfo.sub == actualUserInfo.sub then
                                ( { modelWithActualUserInfo
                                    | expectedUserInfo = Just actualUserInfo
                                    , accessTokenState = verified
                                  }
                                , Cmd.none
                                )

                            else
                                ( modelWithActualUserInfo
                                , Cmd.none
                                )

                        Nothing ->
                            let
                                localStorageIsClean =
                                    modelWithActualUserInfo.localDrafts
                                        |> Dict.isEmpty

                                -- TODO Check blueprints
                            in
                            if localStorageIsClean then
                                ( { modelWithActualUserInfo
                                    | expectedUserInfo = Just actualUserInfo
                                    , accessTokenState = verified
                                  }
                                , Cmd.none
                                )

                            else
                                ( modelWithActualUserInfo
                                , Cmd.none
                                )

                Err error ->
                    let
                        initializationError =
                            case error of
                                DetailedHttpError.NetworkError ->
                                    NetworkMissing

                                _ ->
                                    ServerError error

                        newAccessTokenState =
                            case ( modelWithActualUserInfo.accessTokenState, error ) of
                                ( Verifying accessToken, DetailedHttpError.InvalidAccessToken ) ->
                                    Expired accessToken

                                ( Verified { accessToken }, DetailedHttpError.InvalidAccessToken ) ->
                                    Expired accessToken

                                _ ->
                                    modelWithActualUserInfo.accessTokenState
                    in
                    ( { modelWithActualUserInfo
                        | accessTokenState = newAccessTokenState
                        , error = Just initializationError
                      }
                    , Ports.Console.errorString (DetailedHttpError.toString error)
                    )

        GotDraftLoadResponse { request, result } ->
            let
                modelWithActualDraft =
                    Cache.withResult request result model.actualDrafts
                        |> flip withActualDrafts model
            in
            case
                determineDraftConflict
                    { local = Dict.get request modelWithActualDraft.localDrafts
                    , expected = Dict.get request modelWithActualDraft.expectedDrafts
                    , actual = RemoteData.fromResult result
                    }
            of
                DoNothing ->
                    modelWithActualDraft
                        |> noCmd

                KeepLocal localDraft ->
                    case modelWithActualDraft.accessTokenState of
                        Verified { accessToken } ->
                            modelWithActualDraft
                                |> withSavingDraft localDraft
                                |> withCmd (Draft.saveToServer accessToken GotDraftSaveResponse localDraft)

                        _ ->
                            modelWithActualDraft
                                |> withCmd (Ports.Console.errorString "aa167786    Access token expired during initialization")

                KeepActual actualDraft ->
                    { modelWithActualDraft
                        | localDrafts = Dict.insert request (Ok actualDraft) modelWithActualDraft.localDrafts
                        , expectedDrafts = Dict.insert request (Ok actualDraft) modelWithActualDraft.expectedDrafts
                    }
                        |> noCmd

                Error DetailedHttpError.InvalidAccessToken ->
                    modelWithActualDraft
                        |> withExpiredAccessToken
                        |> withCmd (Ports.Console.errorString "Access token expired or invalid")

                Error error ->
                    modelWithActualDraft
                        |> withCmd (DetailedHttpError.consoleError error)

                ResolveManually _ ->
                    modelWithActualDraft
                        |> noCmd

        GotDraftSaveResponse requestResult ->
            let
                { request, result } =
                    requestResult

                draftId =
                    request.id

                modelWithSavedDraft =
                    withSavedDraft requestResult model
            in
            case result of
                Ok () ->
                    ( { modelWithSavedDraft
                        | actualDrafts = Cache.withValue draftId request model.actualDrafts
                        , localDrafts = Dict.insert draftId (Ok request) modelWithSavedDraft.localDrafts
                        , expectedDrafts = Dict.insert draftId (Ok request) modelWithSavedDraft.expectedDrafts
                      }
                    , Cmd.none
                    )

                Err error ->
                    case error of
                        DetailedHttpError.InvalidAccessToken ->
                            ( modelWithSavedDraft
                                |> withExpiredAccessToken
                            , Ports.Console.errorString (DetailedHttpError.toString error)
                            )

                        _ ->
                            ( modelWithSavedDraft
                            , Ports.Console.errorString (DetailedHttpError.toString error)
                            )

        ClickedContinueOffline ->
            ( { model
                | accessTokenState = Missing
              }
            , Cmd.none
            )

        ClickedDraftKeepLocal draftId ->
            case ( model.accessTokenState, Dict.get draftId model.localDrafts ) of
                ( Verified { accessToken }, Just (Ok localDraft) ) ->
                    model
                        |> withSavingDraft localDraft
                        |> withCmd (Draft.saveToServer accessToken GotDraftSaveResponse localDraft)

                _ ->
                    ( model, Cmd.none )

        ClickedDraftKeepServer draftId ->
            case Cache.get draftId model.actualDrafts of
                RemoteData.Success actualDraft ->
                    { model
                        | localDrafts = Dict.insert draftId (Ok actualDraft) model.localDrafts
                        , expectedDrafts = Dict.insert draftId (Ok actualDraft) model.expectedDrafts
                    }
                        |> noCmd

                _ ->
                    ( model, Cmd.none )

        ClickedImportLocalData ->
            case ( model.accessTokenState, RemoteData.toMaybe model.actualUserInfo ) of
                ( Verifying accessToken, Just actualUserInfo ) ->
                    ( { model
                        | accessTokenState = Verified { accessToken = accessToken, userInfo = actualUserInfo }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ClickedDeleteLocalData ->
            case ( model.accessTokenState, RemoteData.toMaybe model.actualUserInfo ) of
                -- TODO Remove blueprints
                ( Verifying accessToken, Just actualUserInfo ) ->
                    ( { model
                        | accessTokenState =
                            Verified
                                { accessToken = accessToken
                                , userInfo = actualUserInfo
                                }
                        , localDrafts = Dict.empty
                      }
                    , Cmd.batch
                        [ model.localDrafts
                            |> Dict.keys
                            |> List.map Draft.removeFromLocalStorage
                            |> Cmd.batch
                        , model.expectedDrafts
                            |> Dict.keys
                            |> List.map Draft.removeRemoteFromLocalStorage
                            |> Cmd.batch
                        , model.localDraftBooks
                            |> Dict.keys
                            |> List.map DraftBook.removeFromLocalStorage
                            |> Cmd.batch
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        ClickedSignInToOtherAccount ->
            ( model
            , Browser.Navigation.load (Auth0.login (Route.toUrl model.route))
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions =
    always Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        element =
            case model.accessTokenState of
                Missing ->
                    View.ErrorScreen.layout "Missing access token"

                Expired _ ->
                    viewExpiredAccessToken model
                        |> View.Layout.layout

                Verifying _ ->
                    case model.actualUserInfo of
                        RemoteData.NotAsked ->
                            View.ErrorScreen.layout "Todo: User info not asked"

                        RemoteData.Loading ->
                            View.LoadingScreen.layout "Verifying credentials"

                        RemoteData.Failure error ->
                            viewHttpError model error
                                |> View.Layout.layout

                        RemoteData.Success actualUserInfo ->
                            View.Layout.layout <|
                                viewInfo
                                    { title = "New sign in detected"
                                    , icon =
                                        { src = "assets/exception-orange.svg"
                                        , description = "Alert icon"
                                        }
                                    , elements =
                                        case model.expectedUserInfo of
                                            Just expectedUserInfo ->
                                                [ paragraph [ Font.center ]
                                                    [ text "You're trying to sign in as "
                                                    , text actualUserInfo.sub |> el [ Font.color (rgb255 163 179 222) ]
                                                    , text " but there is unsaved data belonging to "
                                                    , text expectedUserInfo.sub |> el [ Font.color (rgb255 163 179 222) ]
                                                    , text ". Either clear the local data and continue or log in to the other account."
                                                    ]
                                                , ViewComponents.textButton [] (Just ClickedDeleteLocalData) "Delete data"
                                                , ViewComponents.textButton [] (Just ClickedSignInToOtherAccount) "Sign in to the other account"
                                                ]

                                            Nothing ->
                                                [ paragraph [ Font.center ]
                                                    [ text "There is unsaved data on the local storage. Either import it to this account or delete it."
                                                    ]
                                                , ViewComponents.textButton [] (Just ClickedImportLocalData) "Import data"
                                                , ViewComponents.textButton [] (Just ClickedDeleteLocalData) "Delete data"
                                                ]
                                    }

                Verified _ ->
                    viewProgress model
                        |> View.Layout.layout
    in
    { title = "Synchronizing"
    , body = [ element ]
    }


viewExpiredAccessToken : Model -> Element Msg
viewExpiredAccessToken model =
    column
        [ centerX
        , centerY
        , spacing 20
        ]
        [ image
            [ width (px 36)
            , centerX
            ]
            { src = "assets/instruction-images/exception.svg"
            , description = "Loading animation"
            }
        , paragraph
            [ width shrink
            , centerX
            , centerY
            , Font.center
            , Font.size 28
            , Font.color color.font.error
            ]
            [ text "Your credentials are either expired or invalid." ]
        , link
            [ width (px 300)
            , centerX
            ]
            { label = ViewComponents.textButton [] Nothing "Sign in"
            , url = Auth0.login (Route.toUrl model.route)
            }
        ]


viewHttpError : Model -> DetailedHttpError -> Element Msg
viewHttpError model error =
    case error of
        DetailedHttpError.NetworkError ->
            column
                []
                [ text "Unable to connect to server"
                , Input.button [] { onPress = Just ClickedContinueOffline, label = text "Continue offline" }
                ]

        DetailedHttpError.InvalidAccessToken ->
            viewExpiredAccessToken model

        _ ->
            View.ErrorScreen.view (DetailedHttpError.toString error)


determineDraftConflict :
    { local : Maybe (Result Decode.Error Draft)
    , expected : Maybe (Result Decode.Error Draft)
    , actual : RemoteData.RemoteData DetailedHttpError Draft
    }
    -> ConflictResolution Draft
determineDraftConflict { local, expected, actual } =
    case actual of
        RemoteData.NotAsked ->
            DoNothing

        RemoteData.Loading ->
            DoNothing

        RemoteData.Failure error ->
            case error of
                DetailedHttpError.NotFound ->
                    case local of
                        Just (Ok localDraft) ->
                            -- TODO maybe manual if there exists an expected draft
                            KeepLocal localDraft

                        _ ->
                            DoNothing

                _ ->
                    DoNothing

        RemoteData.Success actualDraft ->
            case local of
                Just (Ok localDraft) ->
                    case expected of
                        Just (Ok expectedDraft) ->
                            if Draft.eq localDraft expectedDraft then
                                if Draft.eq localDraft actualDraft then
                                    DoNothing

                                else
                                    KeepActual actualDraft

                            else if Draft.eq localDraft actualDraft then
                                KeepActual actualDraft

                            else if Draft.eq expectedDraft actualDraft then
                                KeepLocal localDraft

                            else
                                ResolveManually
                                    { local = localDraft
                                    , expected = Just expectedDraft
                                    , actual = actualDraft
                                    }

                        _ ->
                            if Draft.eq localDraft actualDraft then
                                KeepActual actualDraft

                            else
                                ResolveManually
                                    { local = localDraft
                                    , expected = Nothing
                                    , actual = actualDraft
                                    }

                _ ->
                    KeepActual actualDraft


viewProgress : Model -> Element Msg
viewProgress model =
    let
        drafts =
            model.localDrafts
                |> Dict.toList
                |> List.sortBy Tuple.first
                |> List.map
                    (\( draftId, localResult ) ->
                        { local = localResult
                        , expected = Dict.get draftId model.expectedDrafts
                        , actual = Cache.get draftId model.actualDrafts
                        }
                    )

        draftsNeedingManualResolution =
            model.localDrafts
                |> Dict.keys
                |> List.filterMap
                    (\key ->
                        case
                            determineDraftConflict
                                { local = Dict.get key model.localDrafts
                                , expected = Dict.get key model.expectedDrafts
                                , actual = Cache.get key model.actualDrafts
                                }
                        of
                            ResolveManually record ->
                                Just record

                            _ ->
                                Nothing
                    )

        numberOfDraftsSaving =
            model.savingDrafts
                |> Dict.values
                |> List.filter
                    (\a ->
                        case a of
                            Saving _ ->
                                True

                            _ ->
                                False
                    )
                |> List.length

        numberOfDraftsSaved =
            model.savingDrafts
                |> Dict.values
                |> List.filter
                    (\a ->
                        case a of
                            Saved _ ->
                                True

                            _ ->
                                False
                    )
                |> List.length

        numberOfDraftsLoading =
            model.actualDrafts
                |> Cache.values
                |> List.filter RemoteData.isLoading
                |> List.length

        numberOfDraftsLoaded =
            model.actualDrafts
                |> Cache.values
                |> List.filter (not << RemoteData.isLoading)
                |> List.length

        elements =
            [ column
                [ centerX, spacing 10 ]
                [ row [ width fill ]
                    [ el [ alignLeft ] (text "Loading drafts: ")
                    , [ String.fromInt numberOfDraftsLoaded
                      , "/"
                      , String.fromInt (numberOfDraftsLoading + numberOfDraftsLoaded)
                      ]
                        |> String.concat
                        |> text
                        |> el [ alignRight ]
                    ]
                , row [ width fill ]
                    [ el [ alignLeft ] (text "Saving drafts: ")
                    , [ String.fromInt numberOfDraftsSaved
                      , "/"
                      , String.fromInt (numberOfDraftsSaving + numberOfDraftsSaved)
                      ]
                        |> String.concat
                        |> text
                        |> el [ alignRight ]
                    ]
                ]
            ]
    in
    case List.head draftsNeedingManualResolution of
        Just record ->
            viewResolveDraftConflict record

        Nothing ->
            viewLoading
                { title = "Resolving unsaved data"
                , elements = elements
                }


viewResolveDraftConflict : { local : Draft, expected : Maybe Draft, actual : Draft } -> Element Msg
viewResolveDraftConflict { local, expected, actual } =
    textColumn [ width fill ]
        [ paragraph [ Font.center ] [ text "Conflict" ]
        , paragraph [ width fill, Font.center ]
            [ text "Your local changes on draft "
            , text local.id
            , text " have diverged from the server version. You need to choose which version you want to keep."
            ]
        , ViewComponents.textButton [] (Just (ClickedDraftKeepLocal local.id)) "Keep my local changes"
        , ViewComponents.textButton [] (Just (ClickedDraftKeepServer actual.id)) "Keep the server changes"
        ]


viewLoading :
    { title : String
    , elements : List (Element msg)
    }
    -> Element msg
viewLoading { title, elements } =
    column
        [ centerX
        , centerY
        , spacing 20
        , padding 40
        ]
        ([ paragraph
            [ Font.size 28
            , Font.center
            ]
            [ text title ]
         , image
            [ width (px 36)
            , centerX
            ]
            { src = "assets/spinner.svg"
            , description = "Loading spinner"
            }
         ]
            ++ elements
        )


viewInfo :
    { title : String
    , icon : { src : String, description : String }
    , elements : List (Element msg)
    }
    -> Element msg
viewInfo { title, icon, elements } =
    column
        [ centerX
        , centerY
        , spacing 20
        , padding 40
        ]
        ([ image
            [ width (px 72)
            , centerX
            ]
            icon
         , paragraph
            [ Font.size 28
            , Font.center
            ]
            [ text title ]
         ]
            ++ elements
        )
