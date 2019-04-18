module Page.Draft exposing (Model, Msg, init, subscriptions, update, view)

import Api
import Array exposing (Array)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.Board as Board exposing (Board)
import Data.Direction exposing (Direction(..))
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.History as History
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool exposing (InstructionTool(..))
import Data.Level as Level exposing (Level)
import Data.Position exposing (Position)
import Data.Session as Session exposing (Session)
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Http
import InstructionToolView
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode
import Levels
import Maybe.Extra
import Ports.LocalStorage
import Route
import View.LoadingScreen
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
    , draftId : DraftId
    , state : State
    , error : Maybe String
    , selectedInstructionToolIndex : Maybe Int
    }


type alias LoadedModel =
    { draft : Draft
    , level : Level
    , selectedInstructionToolIndex : Maybe Int
    , state : State
    }


type alias ErrorModel =
    { error : String
    }


getLevel : Model -> Maybe Level
getLevel model =
    model.session.drafts
        |> Maybe.andThen (Dict.get model.draftId)
        |> Maybe.map .levelId
        |> Maybe.andThen (flip Dict.get (Maybe.withDefault Dict.empty model.session.levels))


init : DraftId -> Session -> ( Model, Cmd Msg )
init draftId session =
    let
        model =
            { session = session
            , draftId = draftId
            , state = Editing
            , error = Nothing
            , selectedInstructionToolIndex = Nothing
            }

        maybeLevelDict =
            if Maybe.Extra.isJust session.levels then
                session.levels

            else
                Levels.levels
                    |> List.map (\level -> ( level.id, level ))
                    |> Dict.fromList
                    |> Just
    in
    case maybeLevelDict of
        Just levelDict ->
            case session.drafts of
                Just draftDict ->
                    case Dict.get draftId draftDict of
                        Just draft ->
                            case Dict.get draft.levelId levelDict of
                                Just _ ->
                                    ( model, Cmd.none )

                                Nothing ->
                                    ( { model | error = Just ("Level " ++ draft.levelId ++ " not found") }, Cmd.none )

                        Nothing ->
                            ( { model | error = Just ("Draft " ++ draftId ++ " not found") }, Cmd.none )

                Nothing ->
                    let
                        levelIds =
                            Dict.values levelDict
                                |> List.map .id

                        cmd =
                            case Session.getToken session of
                                Just token ->
                                    Api.getDrafts token levelIds LoadedDrafts

                                Nothing ->
                                    Draft.getDraftsFromLocalStorage "drafts" levelIds
                    in
                    ( model, cmd )

        Nothing ->
            ( model, Api.getLevels LoadedLevels )



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
    | InstructionToolReplaced Int InstructionTool
    | InstructionToolSelected Int
    | InstructionPlaced Position Instruction
    | LoadedDrafts (Result Http.Error (List Draft))
    | LoadedLevels (Result Http.Error (List Level))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            model.session

        maybeDraft =
            Maybe.andThen (Dict.get model.draftId) session.drafts

        maybeLevel =
            case ( maybeDraft, session.levels ) of
                ( Just draft, Just dict ) ->
                    Dict.get draft.levelId dict

                _ ->
                    Nothing

        unchanged =
            ( model, Cmd.none )
    in
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
                    unchanged

        Import importData ->
            case maybeDraft of
                Just draft ->
                    case Decode.decodeString Board.decoder importData of
                        Ok board ->
                            { model | state = Editing }
                                |> updateDraft (Draft.pushBoard board draft)

                        Err error ->
                            ( { model
                                | state =
                                    Importing
                                        { importData = importData
                                        , errorMessage = Just (Decode.errorToString error)
                                        }
                              }
                            , Cmd.none
                            )

                Nothing ->
                    unchanged

        ImportOpen ->
            case maybeDraft of
                Just draft ->
                    ( { model
                        | state =
                            Importing
                                { importData =
                                    History.current draft.boardHistory
                                        |> Board.encode
                                        |> Encode.encode 2
                                , errorMessage = Nothing
                                }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    unchanged

        ImportClosed ->
            ( { model | state = Editing }
            , Cmd.none
            )

        EditUndo ->
            case maybeDraft of
                Just draft ->
                    updateDraft
                        (Draft.undo draft)
                        model

                Nothing ->
                    unchanged

        EditRedo ->
            case maybeDraft of
                Just draft ->
                    updateDraft
                        (Draft.redo draft)
                        model

                Nothing ->
                    unchanged

        EditClear ->
            case ( maybeDraft, maybeLevel ) of
                ( Just draft, Just level ) ->
                    updateDraft
                        (Draft.pushBoard level.initialBoard draft)
                        model

                _ ->
                    unchanged

        ClickedBack ->
            ( model
            , Navigation.back model.session.key 1
            )

        ClickedExecute ->
            ( model
            , Route.pushUrl
                model.session.key
                (Route.ExecuteDraft model.draftId)
            )

        InstructionToolSelected index ->
            ( { model
                | selectedInstructionToolIndex = Just index
              }
            , Cmd.none
            )

        InstructionToolReplaced index instructionTool ->
            case getLevel model of
                Just level ->
                    ( { model
                        | session =
                            Level.withInstructionTool index instructionTool level
                                |> flip Session.withLevel session
                      }
                    , Cmd.none
                    )

                Nothing ->
                    unchanged

        InstructionPlaced position instruction ->
            case maybeDraft of
                Just oldDraft ->
                    let
                        board =
                            oldDraft.boardHistory
                                |> History.current
                                |> Board.set position instruction

                        draft =
                            Draft.pushBoard board oldDraft
                    in
                    updateDraft draft model

                Nothing ->
                    unchanged

        LoadedDrafts result ->
            unchanged

        LoadedLevels result ->
            unchanged


updateDraft : Draft -> Model -> ( Model, Cmd Msg )
updateDraft draft model =
    let
        cmd =
            Draft.saveToLocalStorage draft
    in
    ( { model
        | session = Session.withDraft draft model.session
      }
    , cmd
    )



-- SUBSCRIPTIONS


subscriptions : Sub Msg
subscriptions =
    let
        loadedDraftSub =
            Ports.LocalStorage.storageGetItemResponse
                (\( key, value ) ->
                    Decode.decodeValue (Decode.list Draft.decoder) value
                        |> Result.mapError (Decode.errorToString >> Http.BadBody)
                        |> LoadedDrafts
                )
    in
    Sub.batch
        [ loadedDraftSub
        ]



-- VIEW


view : Model -> Document Msg
view model =
    let
        session =
            model.session

        content =
            case session.levels of
                Just levelDict ->
                    case session.drafts of
                        Just draftDict ->
                            case Dict.get model.draftId draftDict of
                                Just draft ->
                                    case Dict.get draft.levelId levelDict of
                                        Just level ->
                                            viewLoaded
                                                { draft = draft
                                                , level = level
                                                , selectedInstructionToolIndex = model.selectedInstructionToolIndex
                                                , state = model.state
                                                }

                                        Nothing ->
                                            viewError { error = "Level not found" }

                                Nothing ->
                                    viewError { error = "Draft not found" }

                        Nothing ->
                            viewError { error = "Loading drafts" }

                Nothing ->
                    View.LoadingScreen.view "Loading levels"

        body =
            layout
                [ Background.color (rgb 0 0 0)
                , Font.family [ Font.monospace ]
                , Font.color (rgb 1 1 1)
                , height fill
                ]
                content
                |> List.singleton
    in
    { title = "Draft"
    , body = body
    }


instructionSpacing : Int
instructionSpacing =
    10


viewError : ErrorModel -> Element Msg
viewError { error } =
    text error


viewLoaded : LoadedModel -> Element Msg
viewLoaded model =
    let
        maybeSelectedInstructionTool =
            model.selectedInstructionToolIndex
                |> Maybe.andThen (flip Array.get model.level.instructionTools)

        boardView =
            model.draft.boardHistory
                |> History.current
                |> Array.indexedMap (viewRow model.level.initialBoard maybeSelectedInstructionTool)
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

        element =
            row
                [ width fill
                , height fill
                ]
                [ sidebarView
                , importExportBoardView
                , toolSidebarView
                ]
    in
    element


viewSidebar : LoadedModel -> Element Msg
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


viewToolSidebar : LoadedModel -> Element Msg
viewToolSidebar model =
    let
        instructionTools =
            model.level.instructionTools

        viewTool index instructionTool =
            let
                selected =
                    model.selectedInstructionToolIndex
                        |> Maybe.map ((==) index)
                        |> Maybe.withDefault False

                attributes =
                    if selected then
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

                onPress =
                    Just (InstructionToolSelected index)
            in
            instructionToolButton attributes onPress instructionTool

        toolExtraView =
            case model.selectedInstructionToolIndex of
                Just index ->
                    case Array.get index model.level.instructionTools of
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
                                                Just (InstructionToolReplaced index (ChangeAnyDirection direction))

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
                                                    Just (InstructionToolReplaced index (BranchAnyDirection direction falseDirection))
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
                                                    Just (InstructionToolReplaced index (BranchAnyDirection trueDirection direction))
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
                                { onChange = PushValueToStack >> InstructionToolReplaced index
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
