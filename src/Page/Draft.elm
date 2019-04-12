module Page.Draft exposing (Model, Msg, subscriptions, update, view)

import Array exposing (Array)
import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.Board as Board exposing (Board)
import Data.Direction exposing (Direction(..))
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.History as History
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool exposing (InstructionTool(..))
import Data.InstructionToolbox as InstructionToolbox exposing (InstructionToolbox)
import Data.Level exposing (Level)
import Data.Position exposing (Position)
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import InstructionToolView
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode
import Ports.LocalStorage
import Route
import ViewComponents exposing (..)



-- MODEL


type State
    = Editing
    | Importing
        { importData : String
        , errorMessage : Maybe String
        }


type alias Model =
    { session : Session
    , draft : Draft
    , level : Level
    , draftId : DraftId
    , state : State
    , toolbox : InstructionToolbox
    }



-- UPDATE


type Msg
    = ImportDataChanged String
    | Import String
    | ImportOpen
    | ImportClosed
    | EditUndo
    | EditRedo
    | EditClear
    | ClickedBack
    | ClickedExecute
    | ToolboxReplaced InstructionToolbox
    | InstructionPlaced Position Instruction
    | LoadedDraft (Result Decode.Error (Maybe Draft))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ImportDataChanged importData ->
            case model.state of
                Importing _ ->
                    ( { model
                        | state =
                            Importing
                                { importData = importData
                                , errorMessage = Nothing
                                }
                      }
                    , Cmd.none
                    )

                Editing ->
                    ( model, Cmd.none )

        Import importData ->
            case Decode.decodeString Board.decoder importData of
                Ok board ->
                    { model | state = Editing }
                        |> updateDraft (Draft.pushBoard board model.draft)

                Err error ->
                    ( { model
                        | state = Importing { importData = importData, errorMessage = Just (Decode.errorToString error) }
                      }
                    , Cmd.none
                    )

        ImportOpen ->
            ( { model
                | state =
                    Importing
                        { importData =
                            History.current model.draft.boardHistory
                                |> Board.encode
                                |> Encode.encode 2
                        , errorMessage = Nothing
                        }
              }
            , Cmd.none
            )

        ImportClosed ->
            ( { model | state = Editing }
            , Cmd.none
            )

        EditUndo ->
            updateDraft
                (Draft.undo model.draft)
                model

        EditRedo ->
            updateDraft
                (Draft.redo model.draft)
                model

        EditClear ->
            updateDraft
                (Draft.pushBoard model.level.initialBoard model.draft)
                model

        ClickedBack ->
            ( model
            , Navigation.back model.session.key 1
            )

        ClickedExecute ->
            ( model, Route.pushUrl model.session.key (Route.ExecuteDraft model.draft.id) )

        ToolboxReplaced toolbox ->
            ( { model
                | toolbox = toolbox
              }
            , Cmd.none
            )

        InstructionPlaced position instruction ->
            let
                board =
                    model.draft.boardHistory
                        |> History.current
                        |> Board.set position instruction

                draft =
                    Draft.pushBoard board model.draft
            in
            updateDraft draft model

        LoadedDraft result ->
            ( model, Cmd.none )


updateDraft : Draft -> Model -> ( Model, Cmd Msg )
updateDraft draft model =
    let
        cmd =
            Draft.saveToLocalStorage draft
    in
    ( { model | draft = draft }, cmd )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    let
        loadedDraftSub =
            Ports.LocalStorage.storageGetItemResponse
                (\( key, value ) ->
                    LoadedDraft (Decode.decodeValue (Decode.nullable Draft.decoder) value)
                )
    in
    Sub.batch
        [ loadedDraftSub
        ]



-- VIEW


instructionSpacing : Int
instructionSpacing =
    10


view : Model -> Document Msg
view model =
    let
        selectedInstructionTool =
            InstructionToolbox.getSelected model.toolbox

        boardView =
            model.draft.boardHistory
                |> History.current
                |> Array.indexedMap (viewRow model.level.initialBoard selectedInstructionTool)
                |> Array.toList
                |> column
                    [ spacing instructionSpacing
                    , scrollbars
                    , width (fillPortion 3)
                    , height fill
                    , padding instructionSpacing
                    ]

        importExportBoardView =
            case model.state of
                Editing ->
                    boardView

                Importing { importData, errorMessage } ->
                    boardView
                        |> el
                            [ width (fillPortion 3)
                            , height fill
                            , inFront
                                (column
                                    [ centerX
                                    , centerY
                                    , Background.color (rgb 0 0 0)
                                    , padding 20
                                    , Font.family [ Font.monospace ]
                                    , Font.color (rgb 1 1 1)
                                    , spacing 10
                                    , Border.width 3
                                    , Border.color (rgb 1 1 1)
                                    ]
                                    [ el
                                        [ Font.size 32
                                        , centerX
                                        ]
                                        (text "Import / Export")
                                    , Input.multiline
                                        [ Background.color (rgb 0 0 0)
                                        , width (px 500)
                                        , height (px 500)
                                        ]
                                        { onChange = ImportDataChanged
                                        , text = importData
                                        , placeholder = Nothing
                                        , spellcheck = False
                                        , label =
                                            Input.labelAbove
                                                []
                                                (text "Copy or paste from here")
                                        }
                                    , errorMessage
                                        |> Maybe.map text
                                        |> Maybe.map List.singleton
                                        |> Maybe.map (paragraph [])
                                        |> Maybe.withDefault none
                                    , ViewComponents.textButton []
                                        (Just (Import importData))
                                        "Import"
                                    , ViewComponents.textButton []
                                        (Just ImportClosed)
                                        "Close"
                                    ]
                                )
                            ]

        sidebarView =
            viewSidebar model

        toolSidebarView =
            viewToolSidebar model

        body =
            row
                [ width fill
                , height fill
                ]
                [ sidebarView
                , importExportBoardView
                , toolSidebarView
                ]
                |> layout
                    [ Background.color (rgb 0 0 0)
                    , Font.family [ Font.monospace ]
                    , Font.color (rgb 1 1 1)
                    , height fill
                    ]
                |> List.singleton
    in
    { title = "Draft"
    , body = body
    }


viewSidebar : Model -> Element Msg
viewSidebar model =
    let
        level =
            model.level

        titleView =
            viewTitle
                []
                level.name

        descriptionView =
            descriptionTextbox []
                level.description

        backButton =
            textButton []
                (Just ClickedBack)
                "Back"

        undoButtonView =
            textButton []
                (Just EditUndo)
                "Undo"

        redoButtonView =
            textButton []
                (Just EditRedo)
                "Redo"

        clearButtonView =
            textButton []
                (Just EditClear)
                "Clear"

        importExportButtonView =
            textButton []
                (Just ImportOpen)
                "Import / Export"

        executeButtonView =
            textButton []
                (Just ClickedExecute)
                "Execute"
    in
    column
        [ px 350 |> width
        , height fill
        , alignTop
        , Background.color (rgb 0.08 0.08 0.08)
        , spacing 10
        , padding 10
        , scrollbarY
        ]
        [ column
            [ width fill
            , spacing 20
            , paddingEach
                { left = 0, top = 20, right = 0, bottom = 30 }
            ]
            [ titleView
            , descriptionView
            , executeButtonView
            ]
        , column
            [ width fill
            , height fill
            , spacing 10
            ]
            [ undoButtonView
            , redoButtonView
            , clearButtonView
            , importExportButtonView
            , el [ alignBottom, width fill ] backButton
            ]
        ]


viewToolSidebar : Model -> Element Msg
viewToolSidebar model =
    let
        instructionToolbox =
            model.toolbox

        instructionTools =
            instructionToolbox.instructionTools

        viewTool index instructionTool =
            let
                attributes =
                    case instructionToolbox.selectedIndex of
                        Just selectedIndex ->
                            if index == selectedIndex then
                                [ Background.color (rgba 1 1 1 0.5)
                                , InstructionToolView.description instructionTool
                                    |> Html.Attributes.title
                                    |> htmlAttribute
                                ]

                            else
                                [ InstructionToolView.description instructionTool
                                    |> Html.Attributes.title
                                    |> htmlAttribute
                                ]

                        Nothing ->
                            [ InstructionToolView.description instructionTool
                                |> Html.Attributes.title
                                |> htmlAttribute
                            ]

                onPress =
                    { instructionToolbox | selectedIndex = Just index }
                        |> ToolboxReplaced
                        |> Just
            in
            instructionToolButton attributes onPress instructionTool

        replaceToolMessage index instructionTool =
            ToolboxReplaced (InstructionToolbox.set index instructionTool instructionToolbox)

        toolExtraView =
            case instructionToolbox.selectedIndex of
                Just index ->
                    case InstructionToolbox.getSelected instructionToolbox of
                        Just (ChangeAnyDirection selectedDirection) ->
                            [ Left, Up, Down, Right ]
                                |> List.map
                                    (\direction ->
                                        let
                                            attributes =
                                                if selectedDirection == direction then
                                                    [ Background.color (rgb 0.5 0.5 0.5) ]

                                                else
                                                    []

                                            onPress =
                                                ChangeAnyDirection direction
                                                    |> replaceToolMessage index
                                                    |> Just

                                            instruction =
                                                ChangeDirection direction
                                        in
                                        instructionButton attributes onPress instruction
                                    )
                                |> wrappedRow
                                    [ spacing 10
                                    , width (px 222)
                                    , centerX
                                    ]

                        Just (BranchAnyDirection trueDirection falseDirection) ->
                            row
                                [ centerX
                                , spacing 10
                                ]
                                [ [ Up, Left, Right, Down ]
                                    |> List.map
                                        (\direction ->
                                            let
                                                attributes =
                                                    if trueDirection == direction then
                                                        [ Background.color (rgb 0.5 0.5 0.5) ]

                                                    else
                                                        []

                                                onPress =
                                                    BranchAnyDirection direction falseDirection
                                                        |> replaceToolMessage index
                                                        |> Just
                                            in
                                            branchDirectionExtraButton attributes onPress True direction
                                        )
                                    |> column
                                        [ spacing 10 ]
                                , [ Up, Left, Right, Down ]
                                    |> List.map
                                        (\direction ->
                                            let
                                                attributes =
                                                    if falseDirection == direction then
                                                        [ Background.color (rgb 0.5 0.5 0.5) ]

                                                    else
                                                        []

                                                onPress =
                                                    BranchAnyDirection trueDirection direction
                                                        |> replaceToolMessage index
                                                        |> Just
                                            in
                                            branchDirectionExtraButton attributes onPress False direction
                                        )
                                    |> column
                                        [ spacing 10 ]
                                ]

                        Just (PushValueToStack value) ->
                            Input.text
                                [ Background.color (rgb 0 0 0)
                                , Border.width 3
                                , Border.color (rgb 1 1 1)
                                , Border.rounded 0
                                ]
                                { onChange =
                                    \string ->
                                        string
                                            |> PushValueToStack
                                            |> replaceToolMessage index
                                , text = value
                                , placeholder = Nothing
                                , label =
                                    Input.labelAbove
                                        []
                                        (text "Enter value")
                                }

                        Just (JustInstruction _) ->
                            none

                        Nothing ->
                            none

                Nothing ->
                    none

        toolsView =
            instructionTools
                |> Array.indexedMap viewTool
                |> Array.toList
                |> wrappedRow
                    [ width (px 222)
                    , spacing 10
                    , centerX
                    ]
    in
    column
        [ width (px 262)
        , height fill
        , Background.color (rgb 0.08 0.08 0.08)
        , spacing 40
        , padding 10
        , scrollbarY
        ]
        [ toolsView
        , toolExtraView
        ]


viewRow : Board -> Maybe InstructionTool -> Int -> Array Instruction -> Element Msg
viewRow initialBoard selectedInstructionTool rowIndex boardRow =
    boardRow
        |> Array.indexedMap (viewInstruction initialBoard selectedInstructionTool rowIndex)
        |> Array.toList
        |> row [ spacing instructionSpacing ]


viewInstruction : Board -> Maybe InstructionTool -> Int -> Int -> Instruction -> Element Msg
viewInstruction initialBoard selectedInstructionTool rowIndex columnIndex instruction =
    let
        initialInstruction =
            Board.get { x = columnIndex, y = rowIndex } initialBoard
                |> Maybe.withDefault NoOp

        editable =
            initialInstruction == NoOp

        attributes =
            if editable then
                []

            else
                let
                    backgroundColor =
                        case initialInstruction of
                            Exception _ ->
                                rgb 0.1 0 0

                            _ ->
                                rgb 0.15 0.15 0.15
                in
                [ Background.color backgroundColor
                , htmlAttribute (Html.Attributes.style "cursor" "not-allowed")
                , mouseOver []
                ]

        onPress =
            if editable then
                selectedInstructionTool
                    |> Maybe.map getInstruction
                    |> Maybe.map (InstructionPlaced { x = columnIndex, y = rowIndex })

            else
                Nothing
    in
    instructionButton attributes onPress instruction


getInstruction : InstructionTool -> Instruction
getInstruction instructionTool =
    case instructionTool of
        JustInstruction instruction ->
            instruction

        ChangeAnyDirection direction ->
            ChangeDirection direction

        BranchAnyDirection trueDirection falseDirection ->
            Branch trueDirection falseDirection

        PushValueToStack value ->
            value
                |> String.toInt
                |> Maybe.map PushToStack
                |> Maybe.withDefault (Exception (value ++ " is not a number"))
