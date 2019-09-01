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
import Data.Draft as Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId exposing (DraftId)
import Data.GetError as GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.SaveError as SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.SolutionBook as SolutionBook exposing (SolutionBook)
import Data.SolutionId exposing (SolutionId)
import Data.SubmitSolutionError as SubmitSolutionError exposing (SubmitSolutionError)
import Data.User as User
import Data.UserInfo as UserInfo exposing (UserInfo)
import Dict exposing (Dict)
import Element exposing (..)
import Element.Font as Font
import Extra.Cmd exposing (noCmd, withCmd)
import Extra.Result
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Ports.Console
import Random
import RemoteData
import Route exposing (Route)
import Url
import View.Constant exposing (color)
import View.ErrorScreen
import View.Info as Info
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
        , actual : Maybe a
        }
    | Error GetError


type Saving e a
    = Saving a
    | Saved (Result e a)


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
    , actualUserInfo : RemoteData.RemoteData GetError UserInfo
    , localDraftBooks : Dict LevelId DraftBook
    , localDrafts : Dict DraftId Draft
    , expectedDrafts : Dict DraftId Draft
    , actualDrafts : Cache DraftId GetError (Maybe Draft)
    , savingDrafts : Dict DraftId (Saving SaveError Draft)
    , localSolutionBooks : Dict LevelId SolutionBook
    , localSolutions : Dict SolutionId Solution
    , expectedSolutions : Dict SolutionId Solution
    , actualSolutions : Cache SolutionId GetError (Maybe Solution)
    , savingSolutions : Dict SolutionId (Saving SubmitSolutionError Solution)
    }


type Msg
    = GeneratedSolution Solution
    | GotUserInfoResponse (Result GetError UserInfo)
    | GotDraftLoadResponse DraftId (Result GetError (Maybe Draft))
    | GotDraftSaveResponse Draft (Maybe SaveError)
    | GotSolutionSaveResponse Solution (Maybe SubmitSolutionError)
    | ClickedContinueOffline
    | ClickedDraftDeleteLocal DraftId
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

        ( localDrafts, localDraftErrors ) =
            localStorageEntries
                |> List.filterMap Draft.localStorageResponse
                |> List.filterMap RequestResult.extractMaybe
                |> RequestResult.split

        ( expectedDrafts, expectedDraftErrors ) =
            localStorageEntries
                |> List.filterMap Draft.localRemoteStorageResponse
                |> List.filterMap RequestResult.extractMaybe
                |> RequestResult.split

        ( localDraftBooks, localDraftBookErrors ) =
            localStorageEntries
                |> List.filterMap DraftBook.localStorageResponse
                |> RequestResult.split

        ( localSolutions, localSolutionErrors ) =
            localStorageEntries
                |> List.filterMap Solution.localStorageResponse
                |> List.filterMap RequestResult.extractMaybe
                |> RequestResult.split

        ( expectedSolutions, expectedSolutionErrors ) =
            localStorageEntries
                |> List.filterMap Solution.localRemoteStorageResponse
                |> List.filterMap RequestResult.extractMaybe
                |> RequestResult.split

        ( localSolutionBooks, localSolutionBookErrors ) =
            localStorageEntries
                |> List.filterMap SolutionBook.localStorageResponse
                |> RequestResult.split

        model : Model
        model =
            { session =
                Session.init navigationKey url

            --                    |> Levels.withTestLevels
            , route = route
            , accessTokenState =
                accessToken
                    |> Maybe.map Verifying
                    |> Maybe.withDefault Missing
            , expectedUserInfo = Maybe.andThen Result.toMaybe expectedUserInfoResult
            , actualUserInfo = RemoteData.NotAsked
            , localDraftBooks = Dict.fromList localDraftBooks
            , localDrafts = Dict.fromList localDrafts
            , expectedDrafts = Dict.fromList expectedDrafts
            , actualDrafts = Cache.empty
            , savingDrafts = Dict.empty
            , localSolutionBooks = Dict.fromList localSolutionBooks
            , localSolutions = Dict.fromList localSolutions
            , expectedSolutions = Dict.fromList expectedSolutions
            , actualSolutions = Cache.empty
            , savingSolutions = Dict.empty
            }

        cmd : Cmd Msg
        cmd =
            Cmd.batch
                [ accessTokenCmd
                , expectedUserInfoResult
                    |> Maybe.andThen Extra.Result.getError
                    |> Maybe.map Decode.errorToString
                    |> Maybe.map Ports.Console.errorString
                    |> Maybe.withDefault Cmd.none
                , localDraftErrors
                    |> List.map Tuple.second
                    |> List.map Decode.errorToString
                    |> List.map Ports.Console.errorString
                    |> Cmd.batch
                , expectedDraftErrors
                    |> List.map Tuple.second
                    |> List.map Decode.errorToString
                    |> List.map Ports.Console.errorString
                    |> Cmd.batch
                , localDraftBookErrors
                    |> List.map Tuple.second
                    |> List.map Decode.errorToString
                    |> List.map Ports.Console.errorString
                    |> Cmd.batch
                , localSolutionErrors
                    |> List.map Tuple.second
                    |> List.map Decode.errorToString
                    |> List.map Ports.Console.errorString
                    |> Cmd.batch
                , expectedSolutionErrors
                    |> List.map Tuple.second
                    |> List.map Decode.errorToString
                    |> List.map Ports.Console.errorString
                    |> Cmd.batch
                , localSolutionBookErrors
                    |> List.map Tuple.second
                    |> List.map Decode.errorToString
                    |> List.map Ports.Console.errorString
                    |> Cmd.batch
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
                                |> Dict.values
                                |> List.filterMap
                                    (\localDraft ->
                                        if RemoteData.isNotAsked (Cache.get localDraft.id model.actualDrafts) then
                                            if
                                                Dict.get localDraft.id model.expectedDrafts
                                                    |> Maybe.Extra.filter (Draft.eq localDraft)
                                                    |> Maybe.Extra.isJust
                                            then
                                                Nothing

                                            else
                                                Just localDraft.id

                                        else
                                            Nothing
                                    )
                    in
                    ( loadingDraftIds
                        |> List.foldl Cache.loading model.actualDrafts
                        |> flip withActualDrafts model
                    , Cmd.batch
                        [ loadingDraftIds
                            |> List.map (\draftId -> Draft.loadFromServer (GotDraftLoadResponse draftId) accessToken draftId)
                            |> Cmd.batch
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        publishSolutions : Model -> ( Model, Cmd Msg )
        publishSolutions model =
            case model.accessTokenState of
                Verified { accessToken } ->
                    let
                        unpublishedSolutions =
                            model.localSolutions
                                |> Dict.values
                                |> List.filter (.id >> flip Dict.member model.expectedSolutions >> not)
                                |> List.filter (.id >> flip Dict.member model.savingSolutions >> not)

                        savingSolutions =
                            unpublishedSolutions
                                |> List.foldl (\solution -> Dict.insert solution.id (Saving solution)) model.savingSolutions
                    in
                    ( { model
                        | savingSolutions = savingSolutions
                      }
                    , unpublishedSolutions
                        |> List.map (\solution -> Solution.saveToServer (GotSolutionSaveResponse solution) accessToken solution)
                        |> Cmd.batch
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

                        hasSavingDrafts =
                            model.savingDrafts
                                |> Dict.values
                                |> List.filter isSaving
                                |> List.isEmpty
                                |> not

                        hasSavingSolutions =
                            model.savingSolutions
                                |> Dict.values
                                |> List.filter isSaving
                                |> List.isEmpty
                                |> not

                        done =
                            [ hasDraftConflicts
                            , hasSavingDrafts
                            , hasSavingSolutions
                            ]
                                |> List.any identity
                                |> not
                    in
                    if done then
                        let
                            user =
                                User.authorizedUser accessToken userInfo

                            draftCache =
                                { local =
                                    model.localDrafts
                                        |> Dict.map (always Just)
                                        |> Cache.fromValueDict
                                , expected =
                                    model.expectedDrafts
                                        |> Dict.map (always Just)
                                        |> Cache.fromValueDict
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
                                        |> List.map Draft.saveToLocalStorage
                                        |> Cmd.batch
                                    , model.expectedDrafts
                                        |> Dict.values
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

                    else
                        ( model, Cmd.none )
    in
    Extra.Cmd.fold
        [ loadUserData
        , loadDrafts
        , publishSolutions
        , finish
        ]


withSavingDraft : Draft -> Model -> Model
withSavingDraft draft model =
    { model | savingDrafts = Dict.insert draft.id (Saving draft) model.savingDrafts }


withSavedDraft : Draft -> Maybe SaveError -> Model -> Model
withSavedDraft draft maybeError model =
    case maybeError of
        Just error ->
            { model | savingDrafts = Dict.insert draft.id (Saved (Err error)) model.savingDrafts }

        Nothing ->
            { model | savingDrafts = Dict.insert draft.id (Saved (Ok draft)) model.savingDrafts }


withActualDrafts : Cache DraftId GetError (Maybe Draft) -> Model -> Model
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


isSaving : Saving e a -> Bool
isSaving saving =
    case saving of
        Saving _ ->
            True

        Saved _ ->
            False



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GeneratedSolution solution ->
            let
                localSolutions =
                    Dict.insert solution.id solution model.localSolutions

                localSolutionBooks =
                    Dict.update
                        solution.levelId
                        (Maybe.withDefault (SolutionBook.empty solution.levelId) >> SolutionBook.withSolutionId solution.id >> Just)
                        model.localSolutionBooks
            in
            ( { model
                | localSolutions = localSolutions
                , localSolutionBooks = localSolutionBooks
              }
            , Cmd.none
            )

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
                    ( withExpiredAccessToken modelWithActualUserInfo
                    , Ports.Console.errorString (GetError.toString error)
                    )

        GotDraftLoadResponse draftId result ->
            let
                modelWithActualDraft =
                    Cache.withResult draftId result model.actualDrafts
                        |> flip withActualDrafts model
            in
            case
                determineDraftConflict
                    { local = Dict.get draftId modelWithActualDraft.localDrafts
                    , expected = Dict.get draftId modelWithActualDraft.expectedDrafts
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
                                |> withCmd (Draft.saveToServer (GotDraftSaveResponse localDraft) accessToken localDraft)

                        _ ->
                            modelWithActualDraft
                                |> withCmd (Ports.Console.errorString "aa167786    Access token expired during initialization")

                KeepActual actualDraft ->
                    { modelWithActualDraft
                        | localDrafts = Dict.insert draftId actualDraft modelWithActualDraft.localDrafts
                        , expectedDrafts = Dict.insert draftId actualDraft modelWithActualDraft.expectedDrafts
                    }
                        |> noCmd

                Error (GetError.InvalidAccessToken message) ->
                    modelWithActualDraft
                        |> withExpiredAccessToken
                        |> withCmd (Ports.Console.errorString message)

                Error error ->
                    modelWithActualDraft
                        |> withCmd (GetError.consoleError error)

                ResolveManually _ ->
                    modelWithActualDraft
                        |> noCmd

        GotDraftSaveResponse draft result ->
            let
                modelWithSavedDraft =
                    withSavedDraft draft result model
            in
            case result of
                Nothing ->
                    ( { modelWithSavedDraft
                        | actualDrafts = Cache.withValue draft.id (Just draft) model.actualDrafts
                        , localDrafts = Dict.insert draft.id draft modelWithSavedDraft.localDrafts
                        , expectedDrafts = Dict.insert draft.id draft modelWithSavedDraft.expectedDrafts
                      }
                    , Cmd.none
                    )

                Just error ->
                    case error of
                        SaveError.InvalidAccessToken message ->
                            ( modelWithSavedDraft
                                |> withExpiredAccessToken
                            , SaveError.consoleError error
                            )

                        _ ->
                            ( modelWithSavedDraft
                            , SaveError.consoleError error
                            )

        GotSolutionSaveResponse solution maybeError ->
            let
                modelWithSavedResponse =
                    { model
                        | savingSolutions =
                            Dict.insert solution.id
                                (Saved
                                    (case maybeError of
                                        Just error ->
                                            Err error

                                        Nothing ->
                                            Ok solution
                                    )
                                )
                                model.savingSolutions
                    }
            in
            case maybeError of
                Nothing ->
                    modelWithSavedResponse
                        |> withCmd (Solution.saveRemoteToLocalStorage solution)

                Just error ->
                    case error of
                        SubmitSolutionError.NetworkError ->
                            --TODO Offline
                            withExpiredAccessToken model
                                |> noCmd

                        SubmitSolutionError.InvalidAccessToken message ->
                            withExpiredAccessToken model
                                |> noCmd

                        SubmitSolutionError.Duplicate ->
                            let
                                localSolutionBooks =
                                    Dict.update solution.levelId (Maybe.map (SolutionBook.withoutSolutionId solution.id)) model.localSolutionBooks

                                localSolutions =
                                    Dict.remove solution.id model.localSolutions

                                expectedSolutions =
                                    Dict.remove solution.id model.expectedSolutions

                                actualSolutions =
                                    Cache.withValue solution.id Nothing model.actualSolutions
                            in
                            ( { model
                                | localSolutionBooks = localSolutionBooks
                                , localSolutions = localSolutions
                                , expectedSolutions = expectedSolutions
                                , actualSolutions = actualSolutions
                              }
                            , Cmd.batch
                                [ Solution.removeFromLocalStorage solution.id
                                , Solution.removeRemoteFromLocalStorage solution.id
                                , SolutionBook.removeSolutionIdFromLocalStorage solution.id solution.levelId
                                ]
                            )

                        SubmitSolutionError.ConflictingId ->
                            let
                                localSolutionBooks =
                                    Dict.update solution.levelId (Maybe.map (SolutionBook.withoutSolutionId solution.id)) model.localSolutionBooks

                                localSolutions =
                                    Dict.remove solution.id model.localSolutions

                                expectedSolutions =
                                    Dict.remove solution.id model.expectedSolutions

                                actualSolutions =
                                    Cache.withValue solution.id Nothing model.actualSolutions
                            in
                            ( { model
                                | localSolutionBooks = localSolutionBooks
                                , localSolutions = localSolutions
                                , expectedSolutions = expectedSolutions
                                , actualSolutions = actualSolutions
                              }
                            , Cmd.batch
                                [ Solution.removeFromLocalStorage solution.id
                                , Solution.removeRemoteFromLocalStorage solution.id
                                , SolutionBook.removeSolutionIdFromLocalStorage solution.id solution.levelId
                                , Random.generate GeneratedSolution (Solution.generator solution.levelId solution.score solution.board)
                                ]
                            )

                        SubmitSolutionError.Other _ ->
                            modelWithSavedResponse
                                |> withCmd (SubmitSolutionError.consoleError error)

        ClickedContinueOffline ->
            ( { model
                | accessTokenState = Missing
              }
            , Cmd.none
            )

        ClickedDraftDeleteLocal draftId ->
            ( { model
                | localDrafts = Dict.remove draftId model.localDrafts
                , expectedDrafts = Dict.remove draftId model.expectedDrafts
              }
            , Cmd.batch
                [ Draft.removeFromLocalStorage draftId
                , Draft.removeRemoteFromLocalStorage draftId
                ]
            )

        ClickedDraftKeepLocal draftId ->
            case ( model.accessTokenState, Dict.get draftId model.localDrafts ) of
                ( Verified { accessToken }, Just localDraft ) ->
                    model
                        |> withSavingDraft localDraft
                        |> withCmd (Draft.saveToServer (GotDraftSaveResponse localDraft) accessToken localDraft)

                _ ->
                    ( model, Cmd.none )

        ClickedDraftKeepServer draftId ->
            case Cache.get draftId model.actualDrafts of
                RemoteData.Success (Just actualDraft) ->
                    { model
                        | localDrafts = Dict.insert draftId actualDraft model.localDrafts
                        , expectedDrafts = Dict.insert draftId actualDraft model.expectedDrafts
                    }
                        |> noCmd

                RemoteData.Success Nothing ->
                    { model
                        | localDrafts = Dict.remove draftId model.localDrafts
                        , expectedDrafts = Dict.remove draftId model.expectedDrafts
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
            , Browser.Navigation.load (Auth0.reLogin (Route.toUrl model.route))
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
                    viewExpiredAccessToken model ""
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
                                Info.view
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


viewExpiredAccessToken : Model -> String -> Element Msg
viewExpiredAccessToken model message =
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
            [ text "Your credentials are either expired or invalid. "
            , text message
            ]
        , link
            [ width (px 300)
            , centerX
            ]
            { label = ViewComponents.textButton [] Nothing "Sign in"
            , url = Auth0.login (Route.toUrl model.route)
            }
        , ViewComponents.textButton
            [ width (px 300)
            , centerX
            ]
            (Just ClickedContinueOffline)
            "Continue offline"
        ]


viewHttpError : Model -> GetError -> Element Msg
viewHttpError model error =
    case error of
        GetError.NetworkError ->
            Info.view
                { title = "Unable to connect to server"
                , icon =
                    { src = "assets/exception-orange.svg"
                    , description = "Alert icon"
                    }
                , elements =
                    [ ViewComponents.textButton [] (Just ClickedContinueOffline) "Continue offline"
                    ]
                }

        GetError.InvalidAccessToken message ->
            viewExpiredAccessToken model message

        _ ->
            View.ErrorScreen.view (GetError.toString error)


determineDraftConflict :
    { local : Maybe Draft
    , expected : Maybe Draft
    , actual : RemoteData.RemoteData GetError (Maybe Draft)
    }
    -> ConflictResolution Draft
determineDraftConflict { local, expected, actual } =
    case actual of
        RemoteData.NotAsked ->
            DoNothing

        RemoteData.Loading ->
            DoNothing

        RemoteData.Failure _ ->
            DoNothing

        RemoteData.Success Nothing ->
            case local of
                Just localDraft ->
                    KeepLocal localDraft

                Nothing ->
                    DoNothing

        RemoteData.Success (Just actualDraft) ->
            case local of
                Just localDraft ->
                    case expected of
                        Just expectedDraft ->
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
                                    , actual = Just actualDraft
                                    }

                        _ ->
                            if Draft.eq localDraft actualDraft then
                                KeepActual actualDraft

                            else
                                ResolveManually
                                    { local = localDraft
                                    , expected = Nothing
                                    , actual = Just actualDraft
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
                |> List.filter isSaving
                |> List.length

        numberOfDraftsSaved =
            model.savingDrafts
                |> Dict.values
                |> List.filter (not << isSaving)
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

        numberOfSolutionsSaving =
            model.savingSolutions
                |> Dict.values
                |> List.filter isSaving
                |> List.length

        numberOfSolutionsSaved =
            model.savingSolutions
                |> Dict.values
                |> List.filter (not << isSaving)
                |> List.length

        progressRow description current total =
            row [ width fill ]
                [ el [ alignLeft ] (text description)
                , [ String.fromInt current
                  , "/"
                  , String.fromInt total
                  ]
                    |> String.concat
                    |> text
                    |> el [ alignRight ]
                ]

        elements =
            [ column
                [ centerX, spacing 10 ]
                [ progressRow "Loading drafts: " numberOfDraftsLoaded (numberOfDraftsLoading + numberOfDraftsLoaded)
                , progressRow "Saving drafts: " numberOfDraftsSaved (numberOfDraftsSaving + numberOfDraftsSaved)
                , progressRow "Saving solutions: " numberOfSolutionsSaved (numberOfSolutionsSaving + numberOfSolutionsSaved)
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


viewResolveDraftConflict : { local : Draft, expected : Maybe Draft, actual : Maybe Draft } -> Element Msg
viewResolveDraftConflict { local, expected, actual } =
    let
        elements =
            case actual of
                Just justActual ->
                    [ paragraph [ Font.center ]
                        [ text "Your local changes on draft "
                        , text local.id
                        , text " have diverged from the server version. You need to choose which version you want to keep."
                        ]
                    , ViewComponents.textButton [] (Just (ClickedDraftKeepLocal local.id)) "Keep my local changes"
                    , ViewComponents.textButton [] (Just (ClickedDraftKeepServer justActual.id)) "Keep the server changes"
                    ]

                Nothing ->
                    [ paragraph [ Font.center ]
                        [ text "Draft "
                        , text local.id
                        , text " have been deleted from the server but there is still a copy stored locally. "
                        , text "You need to choose whether you want to keep it or not."
                        ]
                    , ViewComponents.textButton [] (Just (ClickedDraftKeepLocal local.id)) "Keep it"
                    , ViewComponents.textButton [] (Just (ClickedDraftDeleteLocal local.id)) "Discard it"
                    ]
    in
    Info.view
        { title = "Conflict in draft " ++ local.id
        , icon =
            { src = "assets/exception-orange.svg"
            , description = "Alert icon"
            }
        , elements = elements
        }


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
