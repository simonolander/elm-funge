module Page.Draft exposing (Model, Msg(..), getSession, init, load, subscriptions, update, view)

import Array exposing (Array)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.Board as Board exposing (Board)
import Data.Cache as Cache
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.GetError as GetError exposing (GetError)
import Data.History as History
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool as InstructionTool exposing (InstructionTool(..))
import Data.Level as Level exposing (Level)
import Data.Position exposing (Position)
import Data.RemoteCache as RemoteCache
import Data.Session as Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Extra.Cmd exposing (noCmd)
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode
import Maybe.Extra
import RemoteData exposing (RemoteData(..), WebData)
import Route
import SessionUpdate exposing (SessionMsg(..))
import View.Board
import View.ErrorScreen
import View.Header
import View.InstructionTools
import View.Layout
import View.LoadingScreen
import View.Scewn
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
    { session : Session
    , draft : Draft
    , level : Level
    , selectedInstructionToolIndex : Maybe Int
    , state : State
    }


type alias ErrorModel =
    { error : String
    }


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
    | SessionMsg SessionMsg


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
    in
    ( model, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadActualDraft model =
            case ( Session.getAccessToken model.session, Cache.get model.draftId model.session.drafts.actual ) of
                ( Just accessToken, NotAsked ) ->
                    ( model.session.drafts
                        |> RemoteCache.withActualLoading model.draftId
                        |> flip Session.withDraftCache model.session
                        |> flip withSession model
                    , Draft.loadFromServer (SessionMsg << GotLoadDraftByDraftIdResponse model.draftId) accessToken model.draftId
                    )

                _ ->
                    noCmd model

        loadLocalDraft model =
            case Cache.get model.draftId model.session.drafts.local of
                NotAsked ->
                    if Maybe.Extra.isNothing (Session.getAccessToken model.session) || RemoteData.isFailure (Cache.get model.draftId model.session.drafts.actual) then
                        ( model.session.drafts
                            |> RemoteCache.withLocalLoading model.draftId
                            |> flip Session.withDraftCache model.session
                            |> flip withSession model
                        , Draft.loadFromLocalStorage model.draftId
                        )

                    else
                        noCmd model

                _ ->
                    noCmd model

        loadLevel model =
            case
                Cache.get model.draftId model.session.drafts.local
                    |> RemoteData.toMaybe
                    |> Maybe.Extra.join
            of
                Just draft ->
                    case Cache.get draft.levelId model.session.levels of
                        NotAsked ->
                            ( model.session.levels
                                |> Cache.loading draft.levelId
                                |> flip Session.withLevelCache model.session
                                |> flip withSession model
                            , Level.loadFromServer (SessionMsg << GotLoadLevelByLevelIdResponse draft.levelId) draft.levelId
                            )

                        _ ->
                            noCmd model

                Nothing ->
                    noCmd model
    in
    Extra.Cmd.fold
        [ loadActualDraft
        , loadLocalDraft
        , loadLevel
        ]


getSession : Model -> Session
getSession { session } =
    session


withSession : Session -> Model -> Model
withSession session model =
    { model | session = session }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        maybeDraft =
            Cache.get model.draftId model.session.drafts.local
                |> RemoteData.toMaybe
                |> Maybe.Extra.join

        maybeLevel =
            maybeDraft
                |> Maybe.map .levelId
                |> Maybe.map (flip Session.getLevel model.session)
                |> Maybe.andThen RemoteData.toMaybe
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
                    ( model, Cmd.none )

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
                    ( model, Cmd.none )

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
                    ( model, Cmd.none )

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
                    ( model, Cmd.none )

        EditRedo ->
            case maybeDraft of
                Just draft ->
                    updateDraft
                        (Draft.redo draft)
                        model

                Nothing ->
                    ( model, Cmd.none )

        EditClear ->
            case ( maybeDraft, maybeLevel ) of
                ( Just draft, Just level ) ->
                    updateDraft
                        (Draft.pushBoard level.initialBoard draft)
                        model

                _ ->
                    ( model, Cmd.none )

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
            case maybeLevel of
                Just level ->
                    ( { model
                        | session =
                            Level.withInstructionTool index instructionTool level
                                |> flip Session.withLevel model.session
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

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
                    ( model, Cmd.none )

        SessionMsg sessionMsg ->
            SessionUpdate.update sessionMsg model.session
                |> Extra.Cmd.mapModel (flip withSession model)


updateDraft : Draft -> Model -> ( Model, Cmd Msg )
updateDraft draft model =
    let
        cmd =
            case Session.getAccessToken model.session of
                Just accessToken ->
                    Cmd.batch
                        [ Draft.saveToServer (SessionMsg << GotSaveDraftResponse draft) accessToken draft
                        , Draft.saveToLocalStorage draft
                        ]

                Nothing ->
                    Draft.saveToLocalStorage draft
    in
    ( RemoteCache.withLocalValue draft.id (Just draft) model.session.drafts
        |> flip Session.withDraftCache model.session
        |> flip withSession model
    , cmd
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
                    View.ErrorScreen.view error

                Nothing ->
                    case Cache.get model.draftId model.session.drafts.local of
                        NotAsked ->
                            if RemoteData.isLoading (Cache.get model.draftId model.session.drafts.actual) then
                                View.LoadingScreen.view ("Loading draft " ++ model.draftId ++ " from server")

                            else
                                View.ErrorScreen.view ("Not asked for draft: " ++ model.draftId)

                        Loading ->
                            View.LoadingScreen.view ("Loading draft " ++ model.draftId ++ " from local storage")

                        Failure error ->
                            View.ErrorScreen.view (Decode.errorToString error)

                        Success Nothing ->
                            View.ErrorScreen.view ("Draft " ++ model.draftId ++ " not found")

                        Success (Just draft) ->
                            case Session.getLevel draft.levelId session of
                                NotAsked ->
                                    View.ErrorScreen.view ("Not asked for level: " ++ draft.levelId)

                                Loading ->
                                    View.LoadingScreen.view ("Loading level " ++ draft.levelId)

                                Failure error ->
                                    View.ErrorScreen.view (GetError.toString error)

                                Success level ->
                                    viewLoaded
                                        { session = session
                                        , draft = draft
                                        , level = level
                                        , selectedInstructionToolIndex = model.selectedInstructionToolIndex
                                        , state = model.state
                                        }

        body =
            content
                |> View.Layout.layout
                |> List.singleton
    in
    { title = "Draft"
    , body = body
    }


viewLoaded : LoadedModel -> Element Msg
viewLoaded model =
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
                , onReplace = InstructionToolReplaced
                }

        element =
            View.Scewn.view
                { north = Just (View.Header.view model.session)
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
            ]
        ]
