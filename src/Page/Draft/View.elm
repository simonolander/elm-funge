module Page.Draft.View exposing (view)

import Array
import Basics.Extra exposing (flip)
import Data.Board as Board
import Data.Draft exposing (Draft)
import Data.GetError as GetError
import Data.History as History
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool as InstructionTool
import Data.Level exposing (Level)
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Page.Draft.Model exposing (Model, State(..))
import Page.Draft.Msg exposing (Msg(..))
import RemoteData exposing (RemoteData(..))
import Resource.Draft.Update exposing (getDraftByDraftId)
import Route
import Update.Update exposing (getLevelByLevelId)
import View.Board
import View.ErrorScreen
import View.Header
import View.InstructionTools
import View.LoadingScreen
import View.NotFound
import View.Scewn
import ViewComponents exposing (descriptionTextbox, textButton, viewTitle)


type alias LoadedModel =
    { draft : Draft
    , level : Level
    , selectedInstructionToolIndex : Maybe Int
    , state : State
    }


view : Session -> Model -> ( String, Html Msg )
view session model =
    let
        content =
            case getDraftByDraftId model.draftId session of
                NotAsked ->
                    View.ErrorScreen.view ("Not asked for draft: " ++ model.draftId)

                Loading ->
                    View.LoadingScreen.view ("Loading draft " ++ model.draftId ++ " from local storage")

                Failure error ->
                    View.ErrorScreen.view (GetError.toString error)

                Success Nothing ->
                    View.Scewn.view
                        { south = Nothing
                        , center = Just <| View.NotFound.view { id = model.draftId, noun = "draft" }
                        , east = Nothing
                        , west = Nothing
                        , north = Just <| View.Header.view session
                        , modal = Nothing
                        }

                Success (Just draft) ->
                    case getLevelByLevelId draft.levelId session of
                        NotAsked ->
                            View.ErrorScreen.view ("Not asked for level: " ++ draft.levelId)

                        Loading ->
                            View.LoadingScreen.view ("Loading level " ++ draft.levelId)

                        Failure error ->
                            View.ErrorScreen.view (GetError.toString error)

                        Success Nothing ->
                            View.Scewn.view
                                { south = Nothing
                                , center = Just <| View.NotFound.view { id = draft.levelId, noun = "level" }
                                , east = Nothing
                                , west = Nothing
                                , north = Just <| View.Header.view session
                                , modal = Nothing
                                }

                        Success (Just level) ->
                            viewLoaded
                                session
                                { draft = draft
                                , level = level
                                , selectedInstructionToolIndex = model.selectedInstructionToolIndex
                                , state = model.state
                                }
    in
    ( "Draft", content )


viewLoaded : Session -> LoadedModel -> Element Msg
viewLoaded session model =
    let
        maybeSelectedInstructionTool =
            model.selectedInstructionToolIndex
                |> Maybe.andThen (flip Array.get model.level.instructionTools)

        board =
            History.current model.draft.boardHistory

        boardOnClick =
            maybeSelectedInstructionTool
                |> Maybe.map InstructionTool.getInstruction
                |> Maybe.map (\instruction { position } -> InstructionPlaced position instruction)

        disabledPositions =
            Board.instructions model.level.initialBoard
                |> List.filter (.instruction >> (/=) NoOp)
                |> List.map .position

        boardView =
            View.Board.view
                { board = board
                , onClick = boardOnClick
                , selectedPosition = Nothing
                , disabledPositions = disabledPositions
                }

        importModal =
            case model.state of
                Editing ->
                    Nothing

                Deleting ->
                    Just <|
                        column
                            [ centerX
                            , centerY
                            , Background.color (rgb 0 0 0)
                            , padding 20
                            , Font.family [ Font.monospace ]
                            , Font.color (rgb 1 1 1)
                            , spacing 10
                            , Border.width 3
                            , Border.color (rgb 1 1 1)
                            , width (maximum 400 shrink)
                            ]
                            [ paragraph [ Font.center ] [ text "Do you really want to delete this draft?" ]
                            , ViewComponents.textButton [] (Just ClickedConfirmDeleteDraft) "Delete"
                            , ViewComponents.textButton [] (Just ClickedCancelDeleteDraft) "Cancel"
                            ]

                Importing { importData, errorMessage } ->
                    column
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
                        |> Just

        sidebarView =
            viewSidebar model

        toolSidebarView =
            View.InstructionTools.view
                { instructionTools = model.level.instructionTools
                , selectedIndex = model.selectedInstructionToolIndex
                , onSelect = Just InstructionToolSelected
                , onReplace = \index tool -> InstructionToolReplaced index tool
                }

        element =
            View.Scewn.view
                { north = Just (View.Header.view session)
                , west = Just sidebarView
                , center = Just boardView
                , east = Just toolSidebarView
                , south = Nothing
                , modal = importModal
                }
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
            Route.link
                [ width fill ]
                (ViewComponents.textButton [] Nothing "Execute")
                (Route.ExecuteDraft model.draft.id)

        deleteDraftButtonView =
            textButton []
                (Just ClickedDeleteDraft)
                "Delete draft"
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
            ]
        , deleteDraftButtonView
        ]
