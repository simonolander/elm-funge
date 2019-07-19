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
import Data.RemoteCache as RemoteCache
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Data.User as User
import Data.UserInfo as UserInfo exposing (UserInfo)
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
    = ConflictingUserInfo
        { expectedUserInfo : Maybe UserInfo
        , actualUserInfo : UserInfo
        }
    | AccessTokenExpired
    | NetworkMissing
    | ServerError Http.Error


type alias Model =
    { session : Session
    , route : Route
    , localStorageEntries : List ( String, Encode.Value )
    , error : Maybe InitializationError
    , savingDrafts : Cache DraftId ()
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

        user =
            accessToken
                |> Maybe.map (flip User.authorizedUser RemoteData.NotAsked)
                |> Maybe.withDefault User.guest

        draftCache =
            let
                localCache =
                    localStorageEntries
                        |> List.filterMap Draft.localStorageResponse
                        |> List.map RequestResult.convertToHttpError
                        |> Cache.fromRequestResults

                expectedCache =
                    localStorageEntries
                        |> List.filterMap Draft.localRemoteStorageResponse
                        |> List.map RequestResult.convertToHttpError
                        |> Cache.fromRequestResults
            in
            RemoteCache.empty
                |> RemoteCache.withLocal localCache
                |> RemoteCache.withOldRemote expectedCache

        model =
            { session =
                Session.init navigationKey url
                    |> Session.withUser user
                    |> Session.withDraftCache draftCache
            , route = route
            , localStorageEntries = localStorageEntries
            , error = Nothing
            , savingDrafts = Cache.empty
            }

        cmd =
            Cmd.batch
                [ accessTokenCmd ]
    in
    load ( model, cmd )


load : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
load =
    let
        loadUserData ( model, cmd ) =
            let
                user =
                    model.session.user
            in
            case ( User.getToken user, User.getUserInfo user ) of
                ( Just accessToken, RemoteData.NotAsked ) ->
                    ( model
                    , Cmd.batch
                        [ cmd
                        , UserInfo.loadFromServer accessToken GotUserInfoResponse
                        , AccessToken.saveToLocalStorage accessToken
                        ]
                    )

                _ ->
                    ( model, cmd )

        loadDrafts ( model, cmd ) =
            let
                user =
                    model.session.user
            in
            case User.getToken user of
                Just accessToken ->
                    if User.isOnline user then
                        let
                            fold draftId ( mdl, loadDraftCmd ) =
                                if Cache.isNotAsked draftId mdl.session.drafts.newRemote then
                                    case Cache.get draftId mdl.session.drafts.local of
                                        RemoteData.Success localDraft ->
                                            let
                                                loadingActualRemoteDraft =
                                                    ( mdl.session.drafts.newRemote
                                                        |> Cache.loading draftId
                                                        |> flip RemoteCache.withNewRemote model.session.drafts
                                                        |> flip Session.withDraftCache model.session
                                                        |> flip withSession mdl
                                                    , Cmd.batch
                                                        [ loadDraftCmd
                                                        , Draft.loadFromServer accessToken GotDraftResponse draftId
                                                        ]
                                                    )
                                            in
                                            case Cache.get draftId mdl.session.drafts.oldRemote of
                                                RemoteData.Success expectedRemoteDraft ->
                                                    if localDraft == expectedRemoteDraft then
                                                        ( mdl, loadDraftCmd )

                                                    else
                                                        loadingActualRemoteDraft

                                                _ ->
                                                    loadingActualRemoteDraft

                                        _ ->
                                            ( mdl, loadDraftCmd )

                                else
                                    ( mdl, loadDraftCmd )
                        in
                        model.session.drafts.local
                            |> Cache.keys
                            |> List.foldl fold ( model, cmd )

                    else
                        ( model, cmd )

                Nothing ->
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


withSavingDrafts : Cache DraftId () -> Model -> Model
withSavingDrafts cache model =
    { model | savingDrafts = cache }



-- UPDATE


type Msg
    = GotUserInfoResponse (RequestResult AccessToken Http.Error UserInfo)
    | GotDraftResponse (RequestResult DraftId Http.Error Draft)
    | GotDraftSaveResponse (RequestResult Draft Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        withCmd : Cmd msg -> Model -> ( Model, Cmd msg )
        withCmd cmd mdl =
            ( mdl, cmd )
    in
    load <|
        case msg of
            GotUserInfoResponse requestResult ->
                case requestResult.result of
                    Ok actualUserInfo ->
                        case
                            model.localStorageEntries
                                |> List.filterMap UserInfo.localStorageResponse
                                |> List.head
                                |> Maybe.map RequestResult.convertToHttpError
                                |> Maybe.map .result
                        of
                            Just (Ok expectedUserInfo) ->
                                if expectedUserInfo.sub == actualUserInfo.sub then
                                    ( model.session.user
                                        |> User.withUserInfo actualUserInfo
                                        |> User.withOnline True
                                        |> flip Session.withUser model.session
                                        |> flip withSession model
                                    , UserInfo.saveToLocalStorage actualUserInfo
                                    )

                                else
                                    ( model
                                        |> withError
                                            (ConflictingUserInfo
                                                { expectedUserInfo = Just expectedUserInfo
                                                , actualUserInfo = actualUserInfo
                                                }
                                            )
                                    , Cmd.none
                                    )

                            Just (Err error) ->
                                ( model
                                    |> withError
                                        (ConflictingUserInfo
                                            { expectedUserInfo = Nothing
                                            , actualUserInfo = actualUserInfo
                                            }
                                        )
                                , Ports.Console.errorString (Extra.String.fromHttpError error)
                                )

                            Nothing ->
                                ( model
                                    |> withError
                                        (ConflictingUserInfo
                                            { expectedUserInfo = Nothing
                                            , actualUserInfo = actualUserInfo
                                            }
                                        )
                                , Cmd.none
                                )

                    Err error ->
                        let
                            initializationError =
                                case error of
                                    Http.NetworkError ->
                                        NetworkMissing

                                    Http.BadStatus 403 ->
                                        AccessTokenExpired

                                    _ ->
                                        ServerError error
                        in
                        case
                            model.localStorageEntries
                                |> List.filterMap UserInfo.localStorageResponse
                                |> List.head
                                |> Maybe.map RequestResult.convertToHttpError
                                |> Maybe.map .result
                        of
                            Just (Ok expectedUserInfo) ->
                                ( model.session.user
                                    |> User.withUserInfo expectedUserInfo
                                    |> User.withOnline False
                                    |> flip Session.withUser model.session
                                    |> flip withSession model
                                    |> withError initializationError
                                , Cmd.none
                                )

                            Just (Err localStorageError) ->
                                ( model.session.user
                                    |> User.withUserInfoWebData (RemoteData.Failure localStorageError)
                                    |> User.withOnline False
                                    |> flip Session.withUser model.session
                                    |> flip withSession model
                                    |> withError initializationError
                                , Ports.Console.errorString (Extra.String.fromHttpError localStorageError)
                                )

                            Nothing ->
                                ( model.session.user
                                    |> User.withUserInfoWebData (RemoteData.Failure (Http.BadStatus 404))
                                    |> User.withOnline False
                                    |> flip Session.withUser model.session
                                    |> flip withSession model
                                    |> withError initializationError
                                , Ports.Console.errorString "No user info found in local storage"
                                )

            GotDraftResponse { request, result } ->
                load <|
                    case result of
                        Ok actualDraft ->
                            let
                                modelWithActualDraft =
                                    model.session.drafts
                                        |> RemoteCache.withNewRemote (Cache.insert request actualDraft model.session.drafts.newRemote)
                                        |> flip Session.withDraftCache model.session
                                        |> flip withSession model
                            in
                            case Cache.get request modelWithActualDraft.session.drafts.local of
                                RemoteData.Success localDraft ->
                                    if actualDraft == localDraft then
                                        modelWithActualDraft.session.drafts
                                            |> RemoteCache.withOldRemote (Cache.insert request actualDraft modelWithActualDraft.session.drafts.oldRemote)
                                            |> flip Session.withDraftCache modelWithActualDraft.session
                                            |> flip withSession modelWithActualDraft
                                            |> withCmd Cmd.none

                                    else
                                        case Cache.get request modelWithActualDraft.session.drafts.oldRemote of
                                            RemoteData.Success expectedDraft ->
                                                if actualDraft == expectedDraft then
                                                    case Session.getAccessToken modelWithActualDraft.session of
                                                        Just accessToken ->
                                                            modelWithActualDraft
                                                                |> withSavingDrafts (Cache.loading request modelWithActualDraft.savingDrafts)
                                                                |> withCmd (Draft.saveToServer accessToken GotDraftSaveResponse localDraft)

                                                        Nothing ->
                                                            modelWithActualDraft
                                                                |> withError AccessTokenExpired
                                                                |> withCmd (Ports.Console.errorString "Access token disappeared before GotDraftSaveResponse, couldn't save local draft")

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
                            model.session.drafts
                                |> RemoteCache.withNewRemote (Cache.failure request error model.session.drafts.newRemote)
                                |> flip Session.withDraftCache model.session
                                |> flip withSession model
                                |> withCmd (Ports.Console.errorString (Extra.String.fromHttpError error))

            GotDraftSaveResponse { request, result } ->
                let
                    draftId =
                        request.id
                in
                case result of
                    Ok () ->
                        model.session.drafts
                            |> RemoteCache.withOldRemote (Cache.insert draftId request model.session.drafts.oldRemote)
                            |> RemoteCache.withNewRemote (Cache.insert draftId request model.session.drafts.newRemote)
                            |> RemoteCache.withLocal (Cache.insert draftId request model.session.drafts.local)
                            |> flip Session.withDraftCache model.session
                            |> flip withSession model
                            |> withSavingDrafts (Cache.insert draftId () model.savingDrafts)
                            |> withCmd Cmd.none

                    Err error ->
                        model.session.drafts
                            |> RemoteCache.withNewRemote (Cache.failure draftId error model.session.drafts.newRemote)
                            |> flip Session.withDraftCache model.session
                            |> flip withSession model
                            |> withSavingDrafts (Cache.failure draftId error model.savingDrafts)
                            |> withCmd (Ports.Console.errorString (Extra.String.fromHttpError error))


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
