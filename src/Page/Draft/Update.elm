module Page.Draft.Update exposing (load, update)

import Basics.Extra exposing (flip)
import Data.Board as Board
import Data.Cache as Cache
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.Draft as Draft
import Data.History as History
import Data.Level as Level
import Data.Session as Session exposing (Session)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Page.Draft.Model exposing (Model, State(..))
import Page.Draft.Msg exposing (Msg(..))
import RemoteData
import Route
import Service.Draft.DraftService exposing (deleteDraftByDraftId, getDraftByDraftId, loadDraftByDraftId, saveDraft)
import Service.Level.LevelService exposing (getLevelByLevelId, loadLevelByLevelId)
import Update.SessionMsg exposing (SessionMsg)


load : CmdUpdater ( Session, Model ) SessionMsg
load =
    let
        loadDraft ( session, model ) =
            loadDraftByDraftId model.draftId session
                |> CmdUpdater.withModel model

        loadLevel ( session, model ) =
            getDraftByDraftId model.draftId session
                |> RemoteData.toMaybe
                |> Maybe.Extra.join
                |> Maybe.map .levelId
                |> Maybe.map (flip loadLevelByLevelId session)
                |> Maybe.withDefault ( session, Cmd.none )
                |> CmdUpdater.withModel model
    in
    CmdUpdater.batch
        [ loadDraft
        , loadLevel
        ]


update : Msg -> CmdUpdater ( Session, Model ) SessionMsg
update msg tuple =
    let
        ( session, model ) =
            tuple

        maybeDraft =
            getDraftByDraftId model.draftId session
                |> RemoteData.toMaybe
                |> Maybe.Extra.join

        maybeLevel =
            Maybe.map .levelId maybeDraft
                |> Maybe.map (flip getLevelByLevelId session)
                |> Maybe.andThen (RemoteData.toMaybe >> Maybe.Extra.join)
    in
    case msg of
        ImportDataChanged importData ->
            case model.state of
                Importing _ ->
                    { model
                        | state =
                            Importing
                                { importData = importData
                                , errorMessage = Nothing
                                }
                    }
                        |> Tuple.pair session
                        |> CmdUpdater.id

                Deleting ->
                    ( ( session, model ), Cmd.none )

                Editing ->
                    ( ( session, model ), Cmd.none )

        Import importData ->
            case maybeDraft of
                Just draft ->
                    case Decode.decodeString Board.decoder importData of
                        Ok board ->
                            saveDraft (Draft.pushBoard board draft) session
                                |> CmdUpdater.withModel { model | state = Editing }

                        Err error ->
                            ( ( session
                              , { model
                                    | state =
                                        Importing
                                            { importData = importData
                                            , errorMessage = Just (Decode.errorToString error)
                                            }
                                }
                              )
                            , Cmd.none
                            )

                Nothing ->
                    ( tuple, Cmd.none )

        ImportOpen ->
            case maybeDraft of
                Just draft ->
                    ( ( session
                      , { model
                            | state =
                                Importing
                                    { importData =
                                        History.current draft.boardHistory
                                            |> Board.encode
                                            |> Encode.encode 2
                                    , errorMessage = Nothing
                                    }
                        }
                      )
                    , Cmd.none
                    )

                Nothing ->
                    ( tuple, Cmd.none )

        ImportClosed ->
            ( ( session, { model | state = Editing } )
            , Cmd.none
            )

        EditUndo ->
            case maybeDraft of
                Just draft ->
                    saveDraft (Draft.undo draft) session
                        |> CmdUpdater.withModel model

                Nothing ->
                    ( tuple, Cmd.none )

        EditRedo ->
            case maybeDraft of
                Just draft ->
                    saveDraft (Draft.redo draft) session
                        |> CmdUpdater.withModel model

                Nothing ->
                    ( tuple, Cmd.none )

        EditClear ->
            case ( maybeDraft, maybeLevel ) of
                ( Just draft, Just level ) ->
                    saveDraft (Draft.pushBoard level.initialBoard draft) session
                        |> CmdUpdater.withModel model

                _ ->
                    ( tuple, Cmd.none )

        InstructionToolSelected index ->
            ( ( session, { model | selectedInstructionToolIndex = Just index } )
            , Cmd.none
            )

        -- TODO This should probably be done in the model, not in the session
        InstructionToolReplaced index instructionTool ->
            case maybeLevel of
                Just level ->
                    ( ( Level.withInstructionTool index instructionTool
                            |> RemoteData.map
                            |> Cache.update level.id
                            |> flip Session.updateLevels session
                      , model
                      )
                    , Cmd.none
                    )

                Nothing ->
                    ( tuple, Cmd.none )

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
                    saveDraft draft session
                        |> CmdUpdater.withModel model

                Nothing ->
                    ( tuple, Cmd.none )

        ClickedDeleteDraft ->
            ( ( session, { model | state = Deleting } )
            , Cmd.none
            )

        ClickedCancelDeleteDraft ->
            if model.state == Deleting then
                ( ( session, { model | state = Editing } )
                , Cmd.none
                )

            else
                ( tuple, Cmd.none )

        ClickedConfirmDeleteDraft ->
            case maybeDraft of
                Just draft ->
                    let
                        changeRouteCmd =
                            maybeLevel
                                |> Maybe.map .campaignId
                                |> Maybe.map (flip Route.Campaign (Just draft.levelId))
                                |> Maybe.withDefault Route.Home
                                |> Route.replaceUrl session.key
                    in
                    deleteDraftByDraftId draft.id session
                        |> CmdUpdater.withModel model
                        |> CmdUpdater.add changeRouteCmd

                Nothing ->
                    ( tuple, Cmd.none )
