module Main exposing (main)

import Api.Auth0 as Auth0
import ApplicationName exposing (applicationName)
import Basics.Extra exposing (flip, uncurry)
import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.AccessToken as AccessToken
import Data.Blueprint
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, id, mapCmd, withModel, withSession)
import Data.Draft as Draft
import Data.OneOrBoth as OneOrBoth
import Data.RemoteCache as RemoteCache exposing (RemoteCache)
import Data.RequestResult as RequestResult
import Data.Session as Session exposing (Session)
import Data.Solution as Solution
import Data.Updater as Updater exposing (Updater)
import Data.UserInfo as UserInfo
import Data.VerifiedAccessToken exposing (VerifiedAccessToken(..))
import Element
import InterceptorPage.Msg
import InterceptorPage.Update
import InterceptorPage.View
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Page.Init
import Page.Load
import Page.Model as Page
import Page.Msg
import Page.Subscriptions
import Page.Update
import Page.View
import Ports.Console as Console
import Ports.LocalStorage
import Service.Blueprint.BlueprintService as BlueprintService exposing (loadBlueprintsByBlueprintIds)
import Service.Draft.DraftService as DraftService exposing (loadDraftsByDraftIds)
import Service.Solution.SolutionService exposing (loadSolutionsBySolutionIds)
import Update.SessionMsg exposing (SessionMsg)
import Update.Update as Update
import Update.UserInfo exposing (loadUserInfo)
import Url exposing (Url)
import View.Layout



-- MODEL


type alias Flags =
    { width : Int
    , height : Int
    , currentTimeMillis : Int
    , localStorageEntries : List ( String, Encode.Value )
    }


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | LocalStorageResponse ( String, Encode.Value )
    | PageMsg Page.Msg.Msg
    | InterceptorPageMsg InterceptorPage.Msg.Msg



-- MAIN


main : Program Flags ( Session, Page.Model ) Msg
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


initLoad : ( Session, Page.Model ) -> ( ( Session, Page.Model ), Cmd Msg )
initLoad ( oldSession, model ) =
    let
        verifyAccessToken session =
            loadUserInfo session

        loadSolutions : CmdUpdater Session SessionMsg
        loadSolutions session =
            OneOrBoth.fromDicts session.solutions.local session.solutions.expected
                |> List.filterMap OneOrBoth.join
                |> List.filter (OneOrBoth.areSame (==) >> not)
                |> List.map (OneOrBoth.map .id >> OneOrBoth.any)
                |> flip loadSolutionsBySolutionIds session
    in
    CmdUpdater.batch
        [ verifyAccessToken
        , DraftService.loadChanged
        , BlueprintService.loadChanged
        , loadSolutions
        ]
        oldSession
        |> withModel model
        |> fromSessionMsg


init : Flags -> Url.Url -> Navigation.Key -> ( ( Session, Page.Model ), Cmd Msg )
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

        initialSession =
            Session.empty navigationKey url flags.localStorageEntries
                |> localDraftsUpdater
                |> expectedDraftsUpdater
                |> localSolutionsUpdater
                |> expectedSolutionsUpdater
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
                , accessTokenErrors
                ]
                |> Cmd.batch
    in
    Page.Init.init url
        |> id
        |> withSession initialSession
        |> CmdUpdater.add localStorageErrorCmd
        |> CmdUpdater.andThen initLoad
        |> CmdUpdater.andThen load



-- VIEW


view : ( Session, Page.Model ) -> Document Msg
view ( session, pageModel ) =
    let
        ( title, html ) =
            Tuple.mapSecond View.Layout.layout <|
                case InterceptorPage.View.view session of
                    Just tuple ->
                        Tuple.mapSecond (Element.map InterceptorPageMsg) tuple

                    Nothing ->
                        Page.View.view session pageModel
                            |> Tuple.mapSecond PageMsg
    in
    { title = String.concat [ title, " - ", applicationName ]
    , body = [ html ]
    }



-- UPDATE


update : Msg -> CmdUpdater ( Session, Page.Model ) Msg
update msg ( session, pageModel ) =
    CmdUpdater.andThen load <|
        case msg of
            ChangedUrl url ->
                Page.Init.init url
                    |> id
                    |> withSession (Session.withUrl url session)

            ClickedLink urlRequest ->
                case urlRequest of
                    Browser.Internal url ->
                        case url.fragment of
                            Nothing ->
                                ( ( session, pageModel ), Cmd.none )

                            Just _ ->
                                ( ( session, pageModel )
                                , Navigation.pushUrl session.key (Url.toString url)
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
                        ( ( session, pageModel )
                        , cmd
                        )

            LocalStorageResponse ( key, _ ) ->
                ( ( session, pageModel ), Console.infoString ("3h5rn4nu8d3nksmk    " ++ key) )

            PageMsg pageMsg ->
                case pageMsg of
                    Page.Msg.SessionMsg sessionMsg ->
                        Update.update sessionMsg session
                            |> withModel pageModel
                            |> fromSessionMsg

                    Page.Msg.PageMsg internalMsg ->
                        Page.Update.update internalMsg ( session, pageModel )
                            |> mapCmd PageMsg

            InterceptorPageMsg interceptorPageMsg ->
                InterceptorPage.Update.update interceptorPageMsg session
                    |> withModel pageModel
                    |> fromSessionMsg



-- SUBSCRIPTIONS


subscriptions : ( Session, Page.Model ) -> Sub Msg
subscriptions ( _, pageModel ) =
    let
        pageSubscriptions =
            Page.Subscriptions.subscriptions pageModel
                |> Sub.map PageMsg

        localStorageSubscriptions =
            Ports.LocalStorage.storageGetItemResponse LocalStorageResponse
    in
    Sub.batch
        [ pageSubscriptions
        , localStorageSubscriptions
        ]



-- SESSION


fromSessionMsg : ( a, Cmd SessionMsg ) -> ( a, Cmd Msg )
fromSessionMsg =
    mapCmd (Page.Msg.SessionMsg >> PageMsg)


load : CmdUpdater ( Session, Page.Model ) Msg
load =
    Page.Load.load >> mapCmd PageMsg
