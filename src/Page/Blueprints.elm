module Page.Blueprints exposing (Model, Msg, getSession, init, load, subscriptions, update, view)

import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Blueprint as Blueprint
import Data.Cache as Cache
import Data.Campaign as Campaign exposing (Campaign)
import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.GetError as GetError exposing (GetError(..))
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Session as Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Input as Input
import Html exposing (Html)
import Ports.Console
import Random
import RemoteData exposing (RemoteData(..))
import Result exposing (Result)
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
    ( model, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load model =
    case Cache.get CampaignId.blueprints model.session.campaigns of
        NotAsked ->
            case Session.getAccessToken model.session of
                Just accessToken ->
                    ( model.session
                        |> Session.campaignLoading campaignId
                        |> setSession model
                    , Blueprint.loadAllFromServer accessToken GotLoadBlueprintsResponse
                    )

                Nothing ->
                    ( model.session
                        |> Session.campaignLoading campaignId
                        |> setSession model
                    , Campaign.loadFromLocalStorage campaignId
                    )

        -- TODO Blueprints should be a campaign
        Failure error ->
            let
                campaign =
                    Campaign.empty campaignId
            in
            ( model.session
                |> Session.withCampaign campaign
                |> setSession model
            , Campaign.saveToLocalStorage campaign
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
                |> Cmd.batch
            )

        Loading ->
            ( model, Cmd.none )


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
    | GotLoadBlueprintsResponse (Result GetError (List Level))


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

        GotLoadBlueprintsResponse result ->
            case result of
                Ok blueprints ->
                    let
                        campaign =
                            { id = campaignId
                            , levelIds =
                                blueprints
                                    |> List.map .id
                            }

                        cmd =
                            Cmd.batch
                                [ Campaign.saveToLocalStorage campaign
                                , blueprints
                                    |> List.map Level.saveToLocalStorage
                                    |> Cmd.batch
                                ]
                    in
                    ( model.session
                        |> Session.withCampaign campaign
                        |> Session.withLevels blueprints
                        |> setSession model
                    , cmd
                    )

                Err error ->
                    ( model.session
                        |> Session.campaignError campaignId error
                        |> setSession model
                    , Ports.Console.errorString (GetError.toString error)
                    )



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
                            View.LoadingScreen.layout ("Loading " ++ campaignId)

                        Failure error ->
                            View.ErrorScreen.layout (GetError.toString error)

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
                            View.LevelButton.loading levelId

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
