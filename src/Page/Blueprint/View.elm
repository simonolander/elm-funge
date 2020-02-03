module Page.Blueprint.View exposing (view, viewBlueprint)

import Array
import Basics.Extra exposing (flip)
import Data.Blueprint exposing (Blueprint)
import Data.BoardInstruction as BoardInstruction exposing (BoardInstruction)
import Data.CampaignId as CampaignId
import Data.GetError as GetError
import Data.InstructionTool as InstructionTool
import Data.Level as Level
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Html exposing (Html)
import InstructionToolView
import Page.Blueprint.Model exposing (Model)
import Page.Blueprint.Msg exposing (Msg(..))
import RemoteData exposing (RemoteData(..))
import Route
import Service.Blueprint.BlueprintService exposing (getBlueprintByBlueprintId)
import View.Board
import View.Constant exposing (color)
import View.ErrorScreen
import View.Header
import View.Input
import View.InstructionTools
import View.Layout
import View.LoadingScreen
import View.NotFound
import View.Scewn
import ViewComponents


view : Session -> Model -> ( String, Html Msg )
view session model =
    let
        content =
            View.Layout.layout <|
                case getBlueprintByBlueprintId model.blueprintId session of
                    NotAsked ->
                        View.ErrorScreen.view "Not asked :/"

                    Loading ->
                        View.LoadingScreen.view ("Loading blueprint " ++ model.blueprintId)

                    Failure error ->
                        View.ErrorScreen.view (GetError.toString error)

                    Success Nothing ->
                        View.NotFound.view { noun = "blueprint", id = model.blueprintId }

                    Success (Just blueprint) ->
                        viewBlueprint session model blueprint
    in
    ( "Blueprint", content )


viewBlueprint : Session -> Model -> Blueprint -> Element Msg
viewBlueprint session model blueprint =
    let
        header =
            View.Header.view session

        west =
            let
                widthInput =
                    View.Input.numericInput []
                        { text = model.width
                        , labelText = "Width"
                        , onChange = ChangedWidth
                        , placeholder = Nothing
                        , min = Just Level.constraints.minWidth
                        , max = Just Level.constraints.maxWidth
                        , step = Just 1
                        }

                heightInput =
                    View.Input.numericInput []
                        { text = model.height
                        , labelText = "Height"
                        , onChange = ChangedHeight
                        , placeholder = Nothing
                        , min = Just Level.constraints.minHeight
                        , max = Just Level.constraints.maxHeight
                        , step = Just 1
                        }

                inputInput =
                    View.Input.textInput
                        []
                        { onChange = ChangedInput
                        , text = model.input
                        , labelText = "Input"
                        , placeholder = Just "1,2,3,0"
                        }

                outputInput =
                    View.Input.textInput
                        []
                        { onChange = ChangedOutput
                        , text = model.output
                        , labelText = "Output"
                        , placeholder = Just "2,4,6"
                        }

                instructionTools =
                    let
                        enableInstructionToolButton index ( tool, enabled ) =
                            ViewComponents.imageButton
                                [ if enabled then
                                    color.background.selected

                                  else
                                    color.background.black
                                ]
                                (Just (InstructionToolEnabled index))
                                (InstructionToolView.view [] tool)

                        instructionToolRow =
                            model.enabledInstructionTools
                                |> Array.indexedMap enableInstructionToolButton
                                |> Array.toList
                                |> wrappedRow [ spacing 10 ]

                        title =
                            text "Enabled instructions"
                    in
                    column
                        [ width fill
                        ]
                        [ title
                        , instructionToolRow
                        ]

                link =
                    Route.link [] (text "test") (Route.Campaign CampaignId.blueprints (Just blueprint.id))
            in
            column
                [ width fill
                , height fill
                , padding 20
                , spacing 20
                , scrollbars
                , color.background.subtle
                ]
                [ paragraph
                    [ width fill
                    , Font.center
                    ]
                    [ text blueprint.name ]
                , widthInput
                , heightInput
                , inputInput
                , outputInput
                , instructionTools
                , link
                ]

        center =
            let
                board =
                    blueprint.initialBoard

                onClick =
                    model.selectedInstructionToolIndex
                        |> Maybe.andThen (flip Array.get model.instructionTools)
                        |> Maybe.map InstructionTool.getInstruction
                        |> Maybe.map BoardInstruction.withInstruction
                        |> Maybe.map ((<<) InitialInstructionPlaced)

                selectedPosition =
                    Nothing

                disabledPositions =
                    []
            in
            View.Board.view
                { board = board
                , onClick = onClick
                , selectedPosition = selectedPosition
                , disabledPositions = disabledPositions
                }

        east =
            View.InstructionTools.view
                { instructionTools = model.instructionTools
                , selectedIndex = model.selectedInstructionToolIndex
                , onSelect = Just InstructionToolSelected
                , onReplace = InstructionToolReplaced
                }
    in
    View.Scewn.view
        { north = Just header
        , west = Just west
        , center = Just center
        , east = Just east
        , south = Nothing
        , modal = Nothing
        }
