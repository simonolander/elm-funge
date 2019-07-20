module Page.Initialize exposing
    ( Model
    , Msg
    , init
    , load
    , localStorageResponseUpdate
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
import Data.DraftId exposing (DraftId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Data.UserInfo as UserInfo exposing (UserInfo)
import Dict exposing (Dict)
import Extra.Result
import Extra.String
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Ports.Console
import RemoteData
import Route exposing (Route)
import Url
import View.LoadingScreen



-- MODEL


type InitializationError
    = NetworkMissing
    | ServerError Http.Error


type Saving a
    = Saving a
    | Saved (Result Http.Error a)


type AccessTokenState
    = Missing
    | Expired AccessToken
    | Verifying AccessToken
    | Verified AccessToken


type alias Model =
    { session : Session
    , route : Route
    , accessTokenState : AccessTokenState
    , expectedUserInfo : Maybe UserInfo
    , actualUserInfo : RemoteData.WebData UserInfo
    , localDrafts : Dict DraftId (Result Decode.Error Draft)
    , expectedDrafts : Dict DraftId (Result Decode.Error Draft)
    , actualDrafts : Cache DraftId Draft
    , savingDrafts : Dict DraftId (Saving Draft)
    , error : Maybe InitializationError
    }


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

        model =
            { session = Session.init navigationKey url
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
    load ( model, cmd )


load : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
load =
    let
        loadUserData ( model, cmd ) =
            case ( model.accessTokenState, model.actualUserInfo ) of
                ( Verifying accessToken, RemoteData.NotAsked ) ->
                    ( { model
                        | actualUserInfo = RemoteData.Loading
                      }
                    , Cmd.batch
                        [ cmd
                        , UserInfo.loadFromServer accessToken GotUserInfoResponse
                        , AccessToken.saveToLocalStorage accessToken
                        ]
                    )

                _ ->
                    ( model, cmd )

        loadDrafts : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
        loadDrafts ( model, cmd ) =
            case model.accessTokenState of
                Verified accessToken ->
                    let
                        loadingDraftIds =
                            model.localDrafts
                                |> Dict.toList
                                |> List.filterMap
                                    (\( draftId, localDraftResult ) ->
                                        if RemoteData.isNotAsked (Cache.get draftId model.actualDrafts) then
                                            case ( localDraftResult, Dict.get draftId model.expectedDrafts ) of
                                                ( Ok localDraft, Just (Ok expectedDraft) ) ->
                                                    if localDraft == expectedDraft then
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
                        [ cmd
                        , loadingDraftIds
                            |> List.map (Draft.loadFromServer accessToken GotDraftResponse)
                            |> Cmd.batch
                        ]
                    )

                _ ->
                    ( model, cmd )
    in
    flip (List.foldl (flip (|>)))
        [ loadUserData
        , loadDrafts
        ]


withSession : Session -> Model -> Model
withSession session model =
    { model | session = session }


withError : InitializationError -> Model -> Model
withError initializationError model =
    { model | error = Just initializationError }


withSavingDraft : Draft -> Model -> Model
withSavingDraft draft model =
    { model | savingDrafts = Dict.insert draft.id (Saving draft) model.savingDrafts }


withSavedDraft : RequestResult Draft Http.Error any -> Model -> Model
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

                Verified accessToken ->
                    Expired accessToken
    }



-- UPDATE


type Msg
    = GotUserInfoResponse (RequestResult AccessToken Http.Error UserInfo)
    | GotDraftResponse (RequestResult DraftId Http.Error Draft)
    | GotDraftSaveResponse (RequestResult Draft Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        withCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
        withCmd cmd mdl =
            ( mdl, cmd )
    in
    load <|
        case msg of
            GotUserInfoResponse { result } ->
                let
                    modelWithActualUserInfo =
                        { model | actualUserInfo = RemoteData.fromResult result }
                in
                case result of
                    Ok actualUserInfo ->
                        case modelWithActualUserInfo.expectedUserInfo of
                            Just expectedUserInfo ->
                                if expectedUserInfo.sub == actualUserInfo.sub then
                                    ( { modelWithActualUserInfo
                                        | expectedUserInfo = Just actualUserInfo
                                        , accessTokenState =
                                            case modelWithActualUserInfo.accessTokenState of
                                                Verifying accessToken ->
                                                    Verified accessToken

                                                _ ->
                                                    modelWithActualUserInfo.accessTokenState
                                      }
                                    , UserInfo.saveToLocalStorage actualUserInfo
                                    )

                                else
                                    ( modelWithActualUserInfo
                                    , Cmd.none
                                    )

                            Nothing ->
                                ( modelWithActualUserInfo
                                , Cmd.none
                                )

                    Err error ->
                        let
                            initializationError =
                                case error of
                                    Http.NetworkError ->
                                        NetworkMissing

                                    _ ->
                                        ServerError error

                            newAccessTokenState =
                                case ( modelWithActualUserInfo.accessTokenState, error ) of
                                    ( Verifying accessToken, Http.BadStatus 403 ) ->
                                        Expired accessToken

                                    ( Verified accessToken, Http.BadStatus 403 ) ->
                                        Expired accessToken

                                    _ ->
                                        modelWithActualUserInfo.accessTokenState
                        in
                        ( { modelWithActualUserInfo
                            | accessTokenState = newAccessTokenState
                            , error = Just initializationError
                          }
                        , Ports.Console.errorString (Extra.String.fromHttpError error)
                        )

            GotDraftResponse requestResult ->
                let
                    { request, result } =
                        requestResult

                    modelWithActualDraft =
                        Cache.insertRequestResult requestResult model.actualDrafts
                            |> flip withActualDrafts model
                in
                case result of
                    Ok actualDraft ->
                        case Dict.get request modelWithActualDraft.localDrafts of
                            Just (Ok localDraft) ->
                                if actualDraft == localDraft then
                                    ( { modelWithActualDraft
                                        | expectedDrafts = Dict.insert request (Ok actualDraft) modelWithActualDraft.expectedDrafts
                                      }
                                    , Draft.saveRemoteToLocalStorage actualDraft
                                    )

                                else
                                    case ( modelWithActualDraft.accessTokenState, Dict.get request modelWithActualDraft.expectedDrafts ) of
                                        ( Verified accessToken, Just (Ok expectedDraft) ) ->
                                            if actualDraft == expectedDraft then
                                                modelWithActualDraft
                                                    |> withSavingDraft localDraft
                                                    |> withCmd (Draft.saveToServer accessToken GotDraftSaveResponse localDraft)

                                            else
                                                modelWithActualDraft
                                                    |> withCmd Cmd.none

                                        _ ->
                                            modelWithActualDraft
                                                |> withCmd Cmd.none

                            _ ->
                                modelWithActualDraft
                                    |> withCmd Cmd.none

                    Err error ->
                        let
                            initializationError =
                                case error of
                                    Http.NetworkError ->
                                        NetworkMissing

                                    _ ->
                                        ServerError error

                            newAccessTokenState =
                                case ( modelWithActualDraft.accessTokenState, error ) of
                                    ( Verifying accessToken, Http.BadStatus 403 ) ->
                                        Expired accessToken

                                    ( Verified accessToken, Http.BadStatus 403 ) ->
                                        Expired accessToken

                                    _ ->
                                        modelWithActualDraft.accessTokenState
                        in
                        ( { modelWithActualDraft
                            | accessTokenState = newAccessTokenState
                            , error = Just initializationError
                          }
                        , Ports.Console.errorString (Extra.String.fromHttpError error)
                        )

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
                            | actualDrafts = Cache.insert draftId request model.actualDrafts
                            , localDrafts = Dict.insert draftId (Ok request) modelWithSavedDraft.localDrafts
                            , expectedDrafts = Dict.insert draftId (Ok request) modelWithSavedDraft.expectedDrafts
                          }
                        , Cmd.none
                        )

                    Err error ->
                        case error of
                            Http.BadStatus 403 ->
                                ( modelWithSavedDraft
                                    |> withExpiredAccessToken
                                , Ports.Console.errorString (Extra.String.fromHttpError error)
                                )

                            _ ->
                                ( modelWithSavedDraft
                                , Ports.Console.errorString (Extra.String.fromHttpError error)
                                )


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate ( key, value ) model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions =
    always Sub.none



-- VIEW


view : Model -> Document msg
view model =
    let
        a =
            3
    in
    { title = "Home"
    , body = [ View.LoadingScreen.layout "Some loading text" ]
    }
