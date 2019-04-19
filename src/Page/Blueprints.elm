module Page.Blueprints exposing (Model, Msg, getSession, init, subscriptions, update, view)

import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Campaign as Campaign exposing (Campaign)
import Data.CampaignId as CampaignId
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Session as Session exposing (Session)
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Input as Input
import Html exposing (Html)
import Json.Decode as Decode
import Ports.LocalStorage as LocalStorage
import Random
import Route
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


init : Maybe LevelId -> Session -> ( Model, Cmd Msg )
init selectedLevelId session =
    let
        model =
            { session = session
            , selectedLevelId = selectedLevelId
            , error = Nothing
            }

        cmd =
            case Dict.get CampaignId.blueprints session.campaigns of
                Just campaign ->
                    campaign.levelIds
                        |> List.filter (not << flip Dict.member session.levels)
                        |> List.map Level.loadFromLocalStorage
                        |> Cmd.batch

                Nothing ->
                    Campaign.loadFromLocalStorage CampaignId.blueprints
    in
    ( model, cmd )


getSession : Model -> Session
getSession { session } =
    session


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }



-- UPDATE


type Msg
    = LocalStorageResponse ( LocalStorage.Key, LocalStorage.Value )
    | ClickedNewLevel
    | LevelGenerated Level
    | SelectedLevelId LevelId
    | LevelNameChanged String
    | LevelDeleted LevelId


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LevelDeleted levelId ->
            case Dict.get CampaignId.blueprints model.session.campaigns of
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
                                , Campaign.saveToLocalStorage campaign
                                ]
                    in
                    ( newModel, cmd )

                Nothing ->
                    ( model, Cmd.none )

        LevelNameChanged newName ->
            case Maybe.andThen (flip Dict.get model.session.levels) model.selectedLevelId of
                Just oldLevel ->
                    let
                        newLevel =
                            Level.withName newName oldLevel

                        newModel =
                            { model
                                | session =
                                    model.session
                                        |> Session.withLevel newLevel
                            }

                        cmd =
                            Level.saveToLocalStorage newLevel
                    in
                    ( newModel, cmd )

                Nothing ->
                    ( model, Cmd.none )

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
                    Dict.get CampaignId.blueprints session.campaigns
                        |> Maybe.withDefault (Campaign.empty CampaignId.blueprints)
                        |> Campaign.withLevelId level.id

                newModel =
                    { model
                        | session =
                            model.session
                                |> Session.withLevel level
                                |> Session.withCampaign campaign
                    }

                cmd =
                    Cmd.batch
                        [ Level.saveToLocalStorage level
                        , Campaign.saveToLocalStorage campaign
                        ]
            in
            ( newModel, cmd )

        LocalStorageResponse ( key, value ) ->
            if key == Campaign.localStorageKey CampaignId.blueprints then
                case Decode.decodeValue (Decode.maybe Campaign.decoder) value of
                    Ok (Just campaign) ->
                        let
                            newModel =
                                { model | session = Session.withCampaign campaign model.session }

                            cmd =
                                campaign.levelIds
                                    |> List.filter (not << flip Dict.member model.session.levels)
                                    |> List.map Level.loadFromLocalStorage
                                    |> Cmd.batch
                        in
                        ( newModel, cmd )

                    Ok Nothing ->
                        let
                            campaign =
                                Campaign.empty CampaignId.blueprints

                            newModel =
                                { model
                                    | session = Session.withCampaign campaign model.session
                                }

                            cmd =
                                Campaign.saveToLocalStorage campaign
                        in
                        ( newModel, cmd )

                    Err error ->
                        ( { model | error = Just (Decode.errorToString error) }, Cmd.none )

            else
                case Decode.decodeValue (Decode.maybe Level.decoder) value of
                    Ok (Just level) ->
                        let
                            newModel =
                                { model | session = Session.withLevel level model.session }
                        in
                        ( newModel, Cmd.none )

                    Ok Nothing ->
                        ( { model | error = Just ("Level not found: " ++ key) }, Cmd.none )

                    Err error ->
                        ( { model | error = Just (Decode.errorToString error) }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    LocalStorage.storageGetItemResponse LocalStorageResponse



-- VIEW


view : Model -> Document Msg
view model =
    let
        session =
            model.session

        content =
            case model.error of
                Just error ->
                    View.LoadingScreen.layout error

                Nothing ->
                    case Dict.get CampaignId.blueprints session.campaigns of
                        Just campaign ->
                            viewCampaign campaign model

                        Nothing ->
                            View.LoadingScreen.layout ("Loading " ++ CampaignId.blueprints ++ "...")
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
            case Maybe.andThen (flip Dict.get session.levels) model.selectedLevelId of
                Just level ->
                    [ Input.text
                        [ Background.color (rgb 0.2 0.2 0.2) ]
                        { onChange = LevelNameChanged
                        , text = level.name
                        , placeholder = Nothing
                        , label =
                            Input.labelAbove
                                []
                                (text "Level name")
                        }
                    , column
                        [ width fill
                        , scrollbarY
                        ]
                        []
                    , ViewComponents.textButton [] (Just (LevelDeleted level.id)) "Delete"
                    ]

                Nothing ->
                    [ el [ centerX ] (text "Blueprints") ]

        mainContent =
            let
                default =
                    View.LevelButton.default

                plusButton =
                    View.LevelButton.internal
                        { default
                            | onPress = Just ClickedNewLevel
                        }
                        "Create new level"
                        ""

                levelButton levelId =
                    case Dict.get levelId session.levels of
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

                        Nothing ->
                            View.LevelButton.loading

                levelButtons =
                    List.map levelButton campaign.levelIds

                buttons =
                    plusButton :: levelButtons
            in
            buttons
    in
    View.SingleSidebar.view sidebarContent mainContent
