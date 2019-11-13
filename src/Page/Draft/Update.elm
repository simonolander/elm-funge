module Page.Draft.Update exposing (init, load, update)

import Basics.Extra exposing (flip)
import Data.Board as Board
import Data.Cache as Cache
import Data.CmdUpdater as CmdUpdater
import Data.Draft as Draft
import Data.DraftId exposing (DraftId)
import Data.History as History
import Data.Level as Level
import Data.Session as Session exposing (Session)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Page.Draft.Model exposing (Model, State(..))
import Page.Draft.Msg exposing (Msg(..))
import Page.PageMsg as PageMsg exposing (InternalMsg(..), PageMsg)
import RemoteData
import Route
import Update.Draft exposing (deleteDraft, getDraftByDraftId, loadDraftByDraftId, saveDraft)
import Update.Level exposing (getLevelByLevelId, loadLevelByLevelId)


fromMsg : Msg -> PageMsg
fromMsg =
    PageMsg.Draft >> PageMsg.InternalMsg


init : DraftId -> Model
init draftId =
    let
        model =
            { draftId = draftId
            , state = Editing
            , error = Nothing
            , selectedInstructionToolIndex = Nothing
            }
    in
    model


load : ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
load =
    let
        loadDraft ( session, model ) =
            loadDraftByDraftId model.draftId session
                |> CmdUpdater.mapBoth (flip Tuple.pair model) PageMsg.SessionMsg

        loadLevel ( session, model ) =
            getDraftByDraftId model.draftId session
                |> RemoteData.toMaybe
                |> Maybe.Extra.join
                |> Maybe.map .levelId
                |> Maybe.map (flip loadLevelByLevelId session)
                |> Maybe.withDefault ( session, Cmd.none )
                |> CmdUpdater.mapBoth (flip Tuple.pair model) PageMsg.SessionMsg
    in
    CmdUpdater.batch
        [ loadDraft
        , loadLevel
        ]


update : Msg -> ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
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
                        |> CmdUpdater.mapCmd fromMsg

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
                                |> CmdUpdater.mapBoth (flip Tuple.pair { model | state = Editing }) PageMsg.SessionMsg

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
                        |> CmdUpdater.mapBoth (flip Tuple.pair model) PageMsg.SessionMsg

                Nothing ->
                    ( tuple, Cmd.none )

        EditRedo ->
            case maybeDraft of
                Just draft ->
                    saveDraft (Draft.redo draft) session
                        |> CmdUpdater.mapBoth (flip Tuple.pair model) PageMsg.SessionMsg

                Nothing ->
                    ( tuple, Cmd.none )

        EditClear ->
            case ( maybeDraft, maybeLevel ) of
                ( Just draft, Just level ) ->
                    saveDraft (Draft.pushBoard level.initialBoard draft) session
                        |> CmdUpdater.mapBoth (flip Tuple.pair model) PageMsg.SessionMsg

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
                        |> CmdUpdater.mapBoth (flip Tuple.pair model) PageMsg.SessionMsg

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
                    deleteDraft draft.id session
                        |> CmdUpdater.mapBoth (flip Tuple.pair model) PageMsg.SessionMsg
                        |> CmdUpdater.add changeRouteCmd

                Nothing ->
                    ( tuple, Cmd.none )
