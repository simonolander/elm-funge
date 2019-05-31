module Page.Blueprints exposing (Model, Msg, getSession, init, load, subscriptions, update, view)

import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Cache as Cache
import Data.Campaign as Campaign exposing (Campaign)
import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RequestResult as RequestResult
import Data.Session as Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Input as Input
import Extra.String
import Html exposing (Html)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.Console
import Ports.LocalStorage as LocalStorage
import Random
import RemoteData exposing (RemoteData(..))
import Route
import View.ErrorScreen
import View.LevelButton
import View.LoadingScreen
import View.SingleSidebar
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    , selectedLevelId : Maybe LevelId
    , error : Maybe String
    }


campaignId : CampaignId
campaignId =
    CampaignId.blueprints


init : Maybe LevelId -> Session -> ( Model, Cmd Msg )
init selectedLevelId session =
    let
        model =
            { session = session
            , selectedLevelId = selectedLevelId
            , error = Nothing
            }
    in
    load ( model, Cmd.none )


load : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
load ( model, cmd ) =
    case Session.getCampaign CampaignId.blueprints model.session of
        NotAsked ->
            ( model.session
                |> Session.campaignLoading campaignId
                |> setSession model
            , Cmd.batch [ cmd, Campaign.loadFromLocalStorage campaignId ]
            )

        Failure (Http.BadStatus 404) ->
            let
                campaign =
                    Campaign.empty campaignId
            in
            ( model.session
                |> Session.withCampaign campaign
                |> setSession model
            , Cmd.batch [ cmd, Campaign.saveToLocalStorage campaign ]
            )

        Success campaign ->
            let
                notAskedLevelIds =
                    campaign.levelIds
                        |> List.filter (flip Cache.isNotAsked model.session.levels)
            in
            ( notAskedLevelIds
                |> List.foldl Session.levelLoading model.session
                |> setSession model
            , notAskedLevelIds
                |> List.map Level.loadFromLocalStorage
                |> (::) cmd
                |> Cmd.batch
            )

        _ ->
            ( model, cmd )


getSession : Model -> Session
getSession { session } =
    session


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }



-- UPDATE


type Msg
    = ClickedNewLevel
    | LevelGenerated Level
    | SelectedLevelId LevelId
    | LevelNameChanged String
    | LevelDeleted LevelId
    | LevelDescriptionChanged String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LevelDeleted levelId ->
            case
                Session.getCampaign campaignId model.session
                    |> RemoteData.toMaybe
            of
                Just campaign ->
                    let
                        newCampaign =
                            Campaign.withoutLevelId levelId campaign

                        newModel =
                            Session.withCampaign newCampaign model.session
                                |> Session.withoutLevel levelId
                                |> setSession model

                        cmd =
                            Cmd.batch
                                [ Level.removeFromLocalStorage levelId
                                , Campaign.saveToLocalStorage newCampaign
                                ]
                    in
                    ( newModel, cmd )

                Nothing ->
                    ( model, Ports.Console.errorString ("v1mC6LQO : Could not delete level " ++ levelId) )

        LevelNameChanged newName ->
            case
                model.selectedLevelId
                    |> Maybe.map (flip Session.getLevel model.session)
                    |> Maybe.andThen RemoteData.toMaybe
            of
                Just oldLevel ->
                    let
                        newLevel =
                            Level.withName newName oldLevel

                        newModel =
                            Session.withLevel newLevel model.session
                                |> setSession model

                        cmd =
                            Level.saveToLocalStorage newLevel
                    in
                    ( newModel, cmd )

                Nothing ->
                    ( model, Ports.Console.errorString "tWy71t5l : Could not update level name" )

        LevelDescriptionChanged newDescription ->
            case
                model.selectedLevelId
                    |> Maybe.map (flip Session.getLevel model.session)
                    |> Maybe.andThen RemoteData.toMaybe
            of
                Just oldLevel ->
                    let
                        newLevel =
                            Level.withDescription (String.lines newDescription) oldLevel

                        newModel =
                            Session.withLevel newLevel model.session
                                |> setSession model

                        cmd =
                            Level.saveToLocalStorage newLevel
                    in
                    ( newModel, cmd )

                Nothing ->
                    ( model, Ports.Console.errorString "Pm6iHnXM : Could not update level description" )

        SelectedLevelId levelId ->
            ( { model | selectedLevelId = Just levelId }
            , Route.replaceUrl model.session.key (Route.Blueprints (Just levelId))
            )

        ClickedNewLevel ->
            ( model, Random.generate LevelGenerated Level.generator )

        LevelGenerated level ->
            let
                session =
                    model.session

                campaign =
                    Session.getCampaign campaignId session
                        |> RemoteData.withDefault (Campaign.empty campaignId)
                        |> Campaign.withLevelId level.id

                newModel =
                    { model
                        | session =
                            model.session
                                |> Session.withLevel level
                                |> Session.withCampaign campaign
                        , selectedLevelId = Just level.id
                    }

                cmd =
                    Cmd.batch
                        [ Level.saveToLocalStorage level
                        , Campaign.saveToLocalStorage campaign
                        , Route.replaceUrl model.session.key (Route.Blueprints (Just level.id))
                        ]
            in
            ( newModel, cmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions =
    always Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        session =
            model.session

        content =
            case model.error of
                Just error ->
                    View.ErrorScreen.layout error

                Nothing ->
                    case Session.getCampaign campaignId session of
                        NotAsked ->
                            View.ErrorScreen.layout "Not asked :/"

                        Loading ->
                            View.LoadingScreen.layout ("Loading " ++ campaignId ++ "...")

                        Failure error ->
                            View.ErrorScreen.layout (Extra.String.fromHttpError error)

                        Success campaign ->
                            viewCampaign campaign model
    in
    { body = [ content ]
    , title = "Blueprints"
    }


viewCampaign : Campaign -> Model -> Html Msg
viewCampaign campaign model =
    let
        session =
            model.session

        sidebarContent =
            case
                model.selectedLevelId
                    |> Maybe.map (flip Session.getLevel session)
                    |> Maybe.andThen RemoteData.toMaybe
            of
                Just level ->
                    let
                        levelName =
                            Input.text
                                [ Background.color (rgb 0.1 0.1 0.1) ]
                                { onChange = LevelNameChanged
                                , text = level.name
                                , placeholder = Nothing
                                , label =
                                    Input.labelAbove
                                        []
                                        (text "Level name")
                                }

                        levelDescription =
                            Input.multiline
                                [ Background.color (rgb 0.1 0.1 0.1)
                                , height (minimum 200 shrink)
                                ]
                                { onChange = LevelDescriptionChanged
                                , text = String.join "\n" level.description
                                , placeholder = Nothing
                                , label =
                                    Input.labelAbove
                                        []
                                        (text "Level description")
                                , spellcheck = True
                                }

                        openBlueprint =
                            Route.link
                                [ width fill ]
                                (ViewComponents.textButton [] Nothing "Open")
                                (Route.Blueprint level.id)

                        deleteBlueprint =
                            ViewComponents.textButton
                                []
                                (Just (LevelDeleted level.id))
                                "Delete"
                    in
                    [ levelName
                    , levelDescription
                    , openBlueprint
                    , deleteBlueprint
                    ]

                Nothing ->
                    [ el [ centerX ] (text "Blueprints") ]

        mainContent =
            let
                default =
                    View.LevelButton.default

                plusButton =
                    ViewComponents.textButton [] (Just ClickedNewLevel) "Create new level"

                levelButton levelId =
                    case
                        Session.getLevel levelId session
                            |> RemoteData.toMaybe
                    of
                        Just level ->
                            View.LevelButton.view
                                { default
                                    | onPress = Just (SelectedLevelId levelId)
                                    , selected =
                                        model.selectedLevelId
                                            |> Maybe.map ((==) levelId)
                                            |> Maybe.withDefault False
                                }
                                level

                        -- TODO Maybe different cases for loading, error and not asked?
                        Nothing ->
                            View.LevelButton.loading

                levelButtons =
                    List.map levelButton campaign.levelIds
            in
            column
                [ width fill, spacing 30 ]
                [ plusButton
                , wrappedRow
                    [ spacing 20
                    ]
                    levelButtons
                ]
    in
    View.SingleSidebar.layout sidebarContent mainContent model.session
