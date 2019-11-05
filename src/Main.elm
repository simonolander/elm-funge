module Main exposing (main)

import Api.Auth0 as Auth0
import ApplicationName exposing (applicationName)
import Basics.Extra exposing (flip, uncurry)
import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.AccessToken as AccessToken
import Data.Blueprint as Blueprint
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.Draft as Draft
import Data.OneOrBoth as OneOrBoth
import Data.RemoteCache as RemoteCache exposing (RemoteCache)
import Data.RequestResult as RequestResult
import Data.Session as Session exposing (Session)
import Data.Solution as Solution
import Data.Updater as Updater exposing (Updater)
import Data.UserInfo as UserInfo
import Data.VerifiedAccessToken exposing (VerifiedAccessToken(..))
import Html
import InterceptorPage.Msg
import InterceptorPage.Update
import InterceptorPage.View
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Page.Init
import Page.Load
import Page.Model exposing (PageModel)
import Page.PageMsg as PageMsg exposing (PageMsg)
import Page.Subscription
import Page.Update
import Page.View
import Ports.Console as Console
import Ports.LocalStorage
import Update.Blueprint exposing (loadBlueprintsByBlueprintIds)
import Update.Draft exposing (loadDraftsByDraftIds)
import Update.SessionMsg exposing (SessionMsg)
import Update.Solution exposing (loadSolutionsBySolutionIds)
import Update.Update as Update
import Update.UserInfo exposing (loadUserInfo)
import Url exposing (Url)



-- MODEL


type alias Flags =
    { width : Int
    , height : Int
    , currentTimeMillis : Int
    , localStorageEntries : List ( String, Encode.Value )
    }


type alias Model =
    { session : Session
    , pageModel : PageModel
    }


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | LocalStorageResponse ( String, Encode.Value )
    | PageMsg PageMsg
    | InterceptorPageMsg InterceptorPage.Msg.Msg



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }



-- INIT


initLoad : CmdUpdater Model Msg
initLoad model =
    let
        loadDrafts session =
            OneOrBoth.fromDicts session.drafts.local session.drafts.expected
                |> List.filterMap OneOrBoth.join
                |> List.filter (OneOrBoth.areSame Draft.eq >> not)
                |> List.map (OneOrBoth.map .id >> OneOrBoth.any)
                |> flip loadDraftsByDraftIds session

        loadBlueprints session =
            OneOrBoth.fromDicts session.blueprints.local session.blueprints.expected
                |> List.filterMap OneOrBoth.join
                |> List.filter (OneOrBoth.areSame (==) >> not)
                |> List.map (OneOrBoth.map .id >> OneOrBoth.any)
                |> flip loadBlueprintsByBlueprintIds session

        loadSolutions session =
            OneOrBoth.fromDicts session.solutions.local session.solutions.expected
                |> List.filterMap OneOrBoth.join
                |> List.filter (OneOrBoth.areSame (==) >> not)
                |> List.map (OneOrBoth.map .id >> OneOrBoth.any)
                |> flip loadSolutionsBySolutionIds session
    in
    CmdUpdater.batch
        [ loadUserInfo
        , loadDrafts
        , loadBlueprints
        , loadSolutions
        ]
        model.session
        |> Tuple.mapBoth (setSession model) (Cmd.map fromSessionMsg)


init : Flags -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags browserUrl navigationKey =
    let
        ( localStorageAccessToken, accessTokenErrors ) =
            flags.localStorageEntries
                |> List.filterMap AccessToken.localStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst
                    (List.head
                        >> Maybe.andThen Tuple.second
                        >> Maybe.map Unverified
                        >> Maybe.withDefault None
                    )

        ( accessToken, url ) =
            case Auth0.loginResponseFromUrl browserUrl of
                Just loginResponse ->
                    ( Unverified loginResponse.accessToken, loginResponse.url )

                Nothing ->
                    ( localStorageAccessToken, browserUrl )

        ( maybeExpectedUserInfo, userInfoErrors ) =
            flags.localStorageEntries
                |> List.filterMap UserInfo.localStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst (Maybe.Extra.values >> List.head >> Maybe.map Tuple.second)

        ( localDraftsUpdater, localDraftErrors ) =
            flags.localStorageEntries
                |> List.filterMap Draft.localStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst (List.map (uncurry RemoteCache.withLocalValue))
                |> Tuple.mapFirst (Updater.batch >> Session.updateDrafts)

        ( expectedDraftsUpdater, expectedDraftErrors ) =
            flags.localStorageEntries
                |> List.filterMap Draft.localRemoteStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst (List.map (uncurry RemoteCache.withExpectedValue))
                |> Tuple.mapFirst (Updater.batch >> Session.updateDrafts)

        ( localSolutionsUpdater, localSolutionErrors ) =
            flags.localStorageEntries
                |> List.filterMap Solution.localStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst (List.map (uncurry RemoteCache.withLocalValue))
                |> Tuple.mapFirst (Updater.batch >> Session.updateSolutions)

        ( expectedSolutionsUpdater, expectedSolutionErrors ) =
            flags.localStorageEntries
                |> List.filterMap Solution.localRemoteStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst (List.map (uncurry RemoteCache.withExpectedValue))
                |> Tuple.mapFirst (Updater.batch >> Session.updateSolutions)

        ( localBlueprintsUpdater, localBlueprintErrors ) =
            flags.localStorageEntries
                |> List.filterMap Blueprint.localStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst (List.map (uncurry RemoteCache.withLocalValue))
                |> Tuple.mapFirst (Updater.batch >> Session.updateBlueprints)

        ( expectedBlueprintsUpdater, expectedBlueprintErrors ) =
            flags.localStorageEntries
                |> List.filterMap Blueprint.localRemoteStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst (List.map (uncurry RemoteCache.withExpectedValue))
                |> Tuple.mapFirst (Updater.batch >> Session.updateBlueprints)

        initialSession =
            Session.init navigationKey url
                |> localDraftsUpdater
                |> expectedDraftsUpdater
                |> localSolutionsUpdater
                |> expectedSolutionsUpdater
                |> localBlueprintsUpdater
                |> expectedBlueprintsUpdater
                |> Session.withExpectedUserInfo maybeExpectedUserInfo
                |> Session.withAccessToken accessToken

        localStorageErrorCmd =
            List.map
                (List.map Tuple.second
                    >> List.map Decode.errorToString
                    >> List.map Console.errorString
                    >> Cmd.batch
                )
                [ userInfoErrors
                , localDraftErrors
                , expectedDraftErrors
                , localSolutionErrors
                , expectedSolutionErrors
                , localBlueprintErrors
                , expectedBlueprintErrors
                , accessTokenErrors
                ]
                |> Cmd.batch
    in
    Page.Init.init url initialSession
        |> Tuple.mapBoth (uncurry Model) (Cmd.map PageMsg)
        |> CmdUpdater.add localStorageErrorCmd
        |> CmdUpdater.andThen initLoad
        |> CmdUpdater.andThen load



-- VIEW


view : Model -> Document Msg
view model =
    let
        ( title, html ) =
            case InterceptorPage.View.view model.session of
                Just tuple ->
                    Tuple.mapSecond (Html.map InterceptorPageMsg) tuple

                Nothing ->
                    Page.View.view model.session model.pageModel
                        |> Tuple.mapSecond PageMsg
    in
    { title = String.concat [ title, " - ", applicationName ]
    , body = [ html ]
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    CmdUpdater.andThen load <|
        case msg of
            ChangedUrl url ->
                let
                    session =
                        Session.withUrl url model.session
                in
                Page.Init.init url session
                    |> Tuple.mapBoth (setSessionAndPageModel model) (Cmd.map PageMsg)

            ClickedLink urlRequest ->
                case urlRequest of
                    Browser.Internal url ->
                        case url.fragment of
                            Nothing ->
                                ( model, Cmd.none )

                            Just _ ->
                                ( model
                                , Navigation.pushUrl model.session.key (Url.toString url)
                                )

                    Browser.External href ->
                        let
                            cmd =
                                [ if href == Auth0.logout then
                                    Just (Ports.LocalStorage.storageClear ())

                                  else
                                    Nothing
                                , Just (Navigation.load href)
                                ]
                                    |> Maybe.Extra.values
                                    |> Cmd.batch
                        in
                        ( model
                        , cmd
                        )

            LocalStorageResponse ( key, _ ) ->
                ( model, Console.infoString ("3h5rn4nu8d3nksmk    " ++ key) )

            PageMsg pageMsg ->
                case pageMsg of
                    PageMsg.SessionMsg sessionMsg ->
                        Update.update sessionMsg model.session
                            |> Tuple.mapBoth (setSession model) (Cmd.map (PageMsg.SessionMsg >> PageMsg))

                    PageMsg.InternalMsg internalMsg ->
                        Page.Update.update internalMsg ( model.session, model.pageModel )
                            |> Tuple.mapBoth (setSessionAndPageModel model) (Cmd.map PageMsg)

            InterceptorPageMsg interceptorPageMsg ->
                InterceptorPage.Update.update interceptorPageMsg model.session
                    |> Tuple.mapBoth (setSession model) (Cmd.map (PageMsg.SessionMsg >> PageMsg))



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSubscriptions =
            Page.Subscription.subscriptions model.pageModel
                |> Sub.map PageMsg

        localStorageSubscriptions =
            Ports.LocalStorage.storageGetItemResponse LocalStorageResponse
    in
    Sub.batch
        [ pageSubscriptions
        , localStorageSubscriptions
        ]



-- SESSION


fromSessionMsg : SessionMsg -> Msg
fromSessionMsg =
    PageMsg.SessionMsg >> PageMsg


updateSession : Updater Session -> Updater Model
updateSession updater model =
    { model | session = updater model.session }


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }


setSessionAndPageModel : Model -> ( Session, PageModel ) -> Model
setSessionAndPageModel model ( session, pageModel ) =
    { model | session = session, pageModel = pageModel }


load : Model -> ( Model, Cmd Msg )
load model =
    Page.Load.load model.session model.pageModel
        |> Tuple.mapBoth (setSessionAndPageModel model) (Cmd.map PageMsg)
