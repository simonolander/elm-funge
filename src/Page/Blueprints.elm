module Page.Blueprints exposing (Model, Msg(..), init, load, subscriptions, update, view)

import ApplicationName exposing (applicationName)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Blueprint as Blueprint exposing (Blueprint)
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache
import Data.Campaign exposing (Campaign)
import Data.GetError as GetError exposing (GetError(..))
import Data.Session as Session exposing (Session, withSession)
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Extra.Cmd exposing (withExtraCmd)
import Html exposing (Html)
import Maybe.Extra
import Ports.Console as Console
import Random
import RemoteData exposing (RemoteData(..))
import Route
import String.Extra
import Update.Blueprint
import Update.SessionMsg exposing (SessionMsg)
import View.Constant exposing (size)
import View.ErrorScreen
import View.Layout
import View.LevelButton
import View.LoadingScreen
import View.SingleSidebar
import ViewComponents



-- MODEL


type Modal
    = ConfirmDelete BlueprintId


type alias Model =
    { session : Session
    , selectedBlueprintId : Maybe BlueprintId
    , modal : Maybe Modal
    }


type Msg
    = InternalMsg InternalMsg
    | SessionMsg SessionMsg


type InternalMsg
    = BlueprintGenerated Blueprint
    | SelectedBlueprintId BlueprintId
    | BlueprintNameChanged String
    | BlueprintDescriptionChanged String
    | ClickedNewBlueprint
    | ClickedDeleteBlueprint BlueprintId
    | ClickedConfirmDeleteBlueprint
    | ClickedCancelDeleteBlueprint


init : Maybe BlueprintId -> Session -> ( Model, Cmd Msg )
init selectedBlueprintId session =
    let
        model =
            { session = session
            , selectedBlueprintId = selectedBlueprintId
            , modal = Nothing
            }
    in
    ( model, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadBlueprints model =
            Update.Blueprint.loadBlueprints model.session
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)
    in
    Extra.Cmd.fold
        [ loadBlueprints ]



-- UPDATE


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedConfirmDeleteBlueprint ->
            case model.modal of
                Just (ConfirmDelete blueprintId) ->
                    Update.Blueprint.deleteBlueprint blueprintId model.session
                        |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

                Nothing ->
                    ( model, Cmd.none )

        ClickedDeleteBlueprint blueprintId ->
            ( { model | modal = Just (ConfirmDelete blueprintId) }, Cmd.none )

        ClickedCancelDeleteBlueprint ->
            case model.modal of
                Just (ConfirmDelete _) ->
                    ( { model | modal = Nothing }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        BlueprintNameChanged newName ->
            case
                Maybe.map (flip Dict.get model.session.blueprints.local) model.selectedBlueprintId
                    |> Maybe.andThen Maybe.Extra.join
            of
                Just blueprint ->
                    Update.Blueprint.saveBlueprint { blueprint | name = newName } model.session
                        |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

                Nothing ->
                    ( model, Console.errorString "tWy71t5l    Could not update blueprint name: blueprint not found" )

        BlueprintDescriptionChanged newDescription ->
            case
                Maybe.map (flip Dict.get model.session.blueprints.local) model.selectedBlueprintId
                    |> Maybe.andThen Maybe.Extra.join
            of
                Just blueprint ->
                    Update.Blueprint.saveBlueprint { blueprint | description = String.lines newDescription } model.session
                        |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

                Nothing ->
                    ( model, Console.errorString "Pm6iHnXM    Could not update blueprint description: blueprint not found" )

        SelectedBlueprintId blueprintId ->
            ( { model | selectedBlueprintId = Just blueprintId }
            , Route.replaceUrl model.session.key (Route.Blueprints (Just blueprintId))
            )

        ClickedNewBlueprint ->
            ( model, Random.generate (InternalMsg << BlueprintGenerated) Blueprint.generator )

        BlueprintGenerated blueprint ->
            Update.Blueprint.saveBlueprint blueprint model.session
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)
                |> Tuple.mapFirst (\m -> { m | selectedBlueprintId = Just blueprint.id })
                |> withExtraCmd (Route.replaceUrl model.session.key (Route.Blueprints (Just blueprint.id)))



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
            case model.session.actualBlueprintsRequest of
                NotAsked ->
                    viewBlueprints model
                        |> View.Layout.layout
                        |> Html.map InternalMsg

                Loading ->
                    View.LoadingScreen.layout "Loading blueprints"

                Failure error ->
                    View.ErrorScreen.layout (GetError.toString error)

                Success () ->
                    viewBlueprints model
                        |> View.Layout.layout
                        |> Html.map InternalMsg
    in
    { body = [ content ]
    , title = String.concat [ "Blueprints", " - ", applicationName ]
    }


viewBlueprints : Model -> Element InternalMsg
viewBlueprints model =
    let
        session =
            model.session

        sidebarContent =
            Maybe.andThen (flip Dict.get model.session.blueprints.local) model.selectedBlueprintId
                |> Maybe.andThen Maybe.Extra.join
                |> Maybe.map viewSidebar
                |> Maybe.withDefault
                    [ el [ centerX, size.font.sidebar.title ] (text "Blueprints")
                    , paragraph [ Font.center ] [ text "Here you can make your own blueprints. A blueprint is a blueprint that is not yet published. Once you publish a blueprint, you cannot change it." ]
                    ]

        mainContent =
            let
                default =
                    View.LevelButton.default

                plusButton =
                    ViewComponents.textButton [] (Just ClickedNewBlueprint) "Create new blueprint"

                blueprintButton blueprint =
                    View.LevelButton.view
                        { default
                            | onPress = Just (SelectedBlueprintId blueprint.id)
                            , selected =
                                model.selectedBlueprintId
                                    |> Maybe.map ((==) blueprint.id)
                                    |> Maybe.withDefault False
                        }
                        blueprint

                blueprintButtons =
                    Dict.values session.blueprints.local
                        |> Maybe.Extra.values
                        |> List.map blueprintButton
            in
            column
                [ width fill, spacing 30 ]
                [ plusButton
                , wrappedRow
                    [ spacing 20
                    ]
                    blueprintButtons
                ]

        modal =
            Maybe.map (flip viewModal model) model.modal
    in
    View.SingleSidebar.view
        { sidebar = sidebarContent
        , main = mainContent
        , session = model.session
        , modal = modal
        }


viewSidebar : Blueprint -> List (Element InternalMsg)
viewSidebar blueprint =
    let
        blueprintName =
            Input.text
                [ Background.color (rgb 0.1 0.1 0.1) ]
                { onChange = BlueprintNameChanged
                , text = blueprint.name
                , placeholder = Nothing
                , label =
                    Input.labelAbove
                        []
                        (text "Blueprint name")
                }

        blueprintDescription =
            Input.multiline
                [ Background.color (rgb 0.1 0.1 0.1)
                , height (minimum 200 shrink)
                ]
                { onChange = BlueprintDescriptionChanged
                , text = String.join "\n" blueprint.description
                , placeholder = Nothing
                , label =
                    Input.labelAbove
                        []
                        (text "Blueprint description")
                , spellcheck = True
                }

        openBlueprint =
            Route.link
                [ width fill ]
                (ViewComponents.textButton [] Nothing "Open")
                (Route.Blueprint blueprint.id)

        deleteBlueprint =
            ViewComponents.textButton
                []
                (Just (ClickedDeleteBlueprint blueprint.id))
                "Delete"
    in
    [ blueprintName
    , blueprintDescription
    , openBlueprint
    , deleteBlueprint
    ]


viewModal : Modal -> Model -> Element InternalMsg
viewModal modal model =
    case modal of
        ConfirmDelete blueprintId ->
            let
                blueprintName =
                    Dict.get blueprintId model.session.blueprints.local
                        |> Maybe.Extra.join
                        |> Maybe.map .name
                        |> Maybe.map String.trim
                        |> Maybe.andThen String.Extra.nonEmpty
                        |> Maybe.withDefault "no name"
            in
            column
                []
                [ paragraph [ Font.center ]
                    [ text "Do you really want to delete blueprint "
                    , text blueprintName
                    , text " ("
                    , text blueprintId
                    , text ")"
                    , text "?"
                    ]
                , ViewComponents.textButton [] (Just ClickedConfirmDeleteBlueprint) "Delete"
                , ViewComponents.textButton [] (Just ClickedCancelDeleteBlueprint) "Cancel"
                ]
