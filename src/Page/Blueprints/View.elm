module Page.Blueprints.View exposing (view, viewBlueprints, viewModal, viewSidebar)

import Basics.Extra exposing (flip)
import Data.Blueprint exposing (Blueprint)
import Data.GetError as GetError
import Data.Session exposing (Session)
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Maybe.Extra
import Page.Blueprints.Model exposing (Modal(..), Model)
import Page.Blueprints.Msg exposing (Msg(..))
import RemoteData exposing (RemoteData(..))
import Route
import Service.Blueprint.BlueprintService exposing (getAllBlueprintsForUser, getBlueprintByBlueprintId)
import String.Extra
import View.Constant exposing (size)
import View.ErrorScreen
import View.LevelButton
import View.LoadingScreen
import View.SingleSidebar
import ViewComponents


view : Session -> Model -> ( String, Element Msg )
view session model =
    let
        content =
            case getAllBlueprintsForUser session of
                NotAsked ->
                    View.LoadingScreen.view "Figuring out how to get blueprints"

                Loading ->
                    View.LoadingScreen.view "Loading blueprints"

                Failure error ->
                    View.ErrorScreen.view (GetError.toString error)

                Success blueprints ->
                    viewBlueprints blueprints session model
    in
    ( "Blueprints"
    , content
    )


viewBlueprints : List Blueprint -> Session -> Model -> Element Msg
viewBlueprints blueprints session model =
    let
        sidebarContent =
            model.selectedBlueprintId
                |> Maybe.map (flip getBlueprintByBlueprintId session)
                |> Maybe.andThen RemoteData.toMaybe
                |> Maybe.Extra.join
                |> Maybe.map viewSidebar
                |> Maybe.withDefault
                    [ el [ centerX, size.font.sidebar.title ] (text "Blueprints")
                    , paragraph
                        [ Font.center
                        ]
                        [ text "Here you can make your own blueprints. A blueprint is a blueprint that is not yet published. Once you publish a blueprint, you cannot change it."
                        ]
                    ]

        mainContent =
            let
                default =
                    View.LevelButton.default

                plusButton =
                    ViewComponents.textButton [] (Just ClickedNewBlueprint) "Create new blueprint"

                blueprintButton : Blueprint -> Element Msg
                blueprintButton blueprint =
                    View.LevelButton.view
                        { default
                            | onPress = Just (ClickedBlueprint blueprint.id)
                            , selected =
                                model.selectedBlueprintId
                                    |> Maybe.map ((==) blueprint.id)
                                    |> Maybe.withDefault False
                        }
                        blueprint

                blueprintButtons =
                    List.map blueprintButton blueprints
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
            Maybe.map (flip viewModal session) model.modal
    in
    View.SingleSidebar.view
        { sidebar = sidebarContent
        , main = mainContent
        , session = session
        , modal = modal
        }


viewSidebar : Blueprint -> List (Element Msg)
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


viewModal : Modal -> Session -> Element Msg
viewModal modal session =
    case modal of
        ConfirmDelete blueprintId ->
            let
                blueprintName =
                    Dict.get blueprintId session.blueprints.local
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
