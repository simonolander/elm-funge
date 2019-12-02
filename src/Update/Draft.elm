module Update.Draft exposing
    ( deleteDraft
    , getDraftByDraftId
    , getDraftsByLevelId
    , gotDeleteDraftResponse
    , gotLoadDraftResponse
    , gotLoadDraftsByLevelIdResponse
    , gotSaveDraftResponse
    , loadDraftByDraftId
    , loadDraftsByDraftIds
    , loadDraftsByLevelId
    , saveDraft
    )

import Basics.Extra exposing (flip)
import Data.Cache as Cache
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache exposing (RemoteCache)
import Data.SaveError exposing (SaveError)
import Data.SaveRequest exposing (SaveRequest(..))
import Data.Session as Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Debug exposing (todo)
import Dict
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Update.General exposing (gotGetError, gotSaveError)
import Update.SessionMsg exposing (SessionMsg(..))



-- LOAD DRAFT BY DRAFT ID


loadDraftByDraftId : DraftId -> CmdUpdater Session SessionMsg
loadDraftByDraftId draftId session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if Cache.isNotAsked draftId session.drafts.actual then
                ( Session.updateDrafts (RemoteCache.withActualLoading draftId) session
                , Draft.loadFromServer GotLoadDraftByDraftIdResponse draftId accessToken
                )

            else
                ( session, Cmd.none )

        Nothing ->
            ( session, Cmd.none )


loadDraftsByDraftIds : List DraftId -> CmdUpdater Session SessionMsg
loadDraftsByDraftIds draftIds session =
    List.map loadDraftByDraftId draftIds
        |> flip CmdUpdater.batch session


gotLoadDraftResponse : DraftId -> Result GetError (Maybe Draft) -> CmdUpdater Session SessionMsg
gotLoadDraftResponse draftId result session =
    case result of
        Ok maybeDraft ->
            gotDraft draftId maybeDraft session

        Err error ->
            Session.updateDrafts (RemoteCache.withActualError draftId error) session
                |> gotGetError error


getDraftByDraftId : DraftId -> Session -> RemoteData GetError (Maybe Draft)
getDraftByDraftId draftId session =
    case Cache.get draftId session.drafts.actual of
        NotAsked ->
            NotAsked

        Loading ->
            Loading

        Failure _ ->
            Dict.get draftId session.drafts.local
                |> Maybe.Extra.join
                |> RemoteData.succeed

        Success _ ->
            Dict.get draftId session.drafts.local
                |> Maybe.Extra.join
                |> RemoteData.succeed


getDraftsByLevelId : LevelId -> Session -> RemoteData GetError (List Draft)
getDraftsByLevelId levelId session =
    todo ""


loadDraftsByLevelId : LevelId -> CmdUpdater Session SessionMsg
loadDraftsByLevelId levelId session =
    todo ""


gotLoadDraftsByLevelIdResponse : LevelId -> Result GetError (List Draft) -> CmdUpdater Session SessionMsg
gotLoadDraftsByLevelIdResponse levelId result session =
    todo ""



-- SAVE


saveDraft : Draft -> CmdUpdater Session SessionMsg
saveDraft draft session =
    todo ""


gotSaveDraftResponse : Draft -> Maybe SaveError -> CmdUpdater Session SessionMsg
gotSaveDraftResponse draft maybeError session =
    todo ""



-- DELETE


deleteDraft : DraftId -> CmdUpdater Session SessionMsg
deleteDraft draftId session =
    let
        deleteRemote s =
            case VerifiedAccessToken.getValid s.accessToken of
                Just accessToken ->
                    ( Session.updateSavingDraftRequests (Dict.insert draftId (Saving Nothing)) s
                    , Draft.deleteFromServer GotDeleteDraftResponse draftId accessToken
                    )

                Nothing ->
                    ( s, Cmd.none )
    in
    Session.updateDrafts (RemoteCache.withLocalValue draftId Nothing) session
        |> deleteRemote
        |> CmdUpdater.add (Draft.saveToLocalStorage draftId Nothing)


gotDeleteDraftResponse : DraftId -> Maybe SaveError -> CmdUpdater Session SessionMsg
gotDeleteDraftResponse draftId maybeError oldSession =
    let
        session =
            Session.updateSavingDraftRequests (Dict.remove draftId) oldSession
    in
    case maybeError of
        Just error ->
            gotSaveError error session

        Nothing ->
            Session.updateDrafts (RemoteCache.withExpectedValue draftId Nothing) session
                |> Session.updateDrafts (RemoteCache.withActualValue draftId Nothing)
                |> flip Tuple.pair (Draft.saveRemoteToLocalStorage draftId Nothing)



-- PRIVATE


gotDraft : DraftId -> Maybe Draft -> CmdUpdater Session SessionMsg
gotDraft draftId maybeDraft session =
    let
        overwriteLocalDraft s =
            ( Session.updateDrafts (RemoteCache.withLocalValue draftId maybeDraft) s
            , Draft.saveToLocalStorage draftId maybeDraft
            )

        overwriteExpectedDraft s =
            ( Session.updateDrafts (RemoteCache.withExpectedValue draftId maybeDraft) s
            , Draft.saveRemoteToLocalStorage draftId maybeDraft
            )
    in
    Tuple.mapFirst (Session.updateDrafts (RemoteCache.withActualValue draftId maybeDraft)) <|
        case
            ( Dict.get draftId session.drafts.local
            , Dict.get draftId session.drafts.expected
            , maybeDraft
            )
        of
            ( Nothing, _, _ ) ->
                [ overwriteLocalDraft
                , overwriteExpectedDraft
                ]

            ( Just Nothing, Nothing, Nothing ) ->
                [ overwriteExpectedDraft ]

            ( Just Nothing, Nothing, Just _ ) ->
                []

            ( Just Nothing, Just Nothing, _ ) ->
                [ overwriteLocalDraft
                , overwriteExpectedDraft
                ]

            ( Just Nothing, Just (Just _), Nothing ) ->
                [ overwriteExpectedDraft ]

            ( Just Nothing, Just (Just expectedDraft), Just actualDraft ) ->
                if Draft.eq expectedDraft actualDraft then
                    [ deleteDraft draftId ]

                else
                    []

            ( Just (Just _), Nothing, Nothing ) ->
                []

            ( Just (Just localDraft), Nothing, Just actualDraft ) ->
                if Draft.eq localDraft actualDraft then
                    [ overwriteExpectedDraft ]

                else
                    []

            ( Just (Just localDraft), Just Nothing, Nothing ) ->
                [ saveDraft localDraft ]

            ( Just (Just localDraft), Just Nothing, Just actualDraft ) ->
                if Draft.eq localDraft actualDraft then
                    [ overwriteExpectedDraft ]

                else
                    []

            ( Just (Just localDraft), Just (Just expectedDraft), Nothing ) ->
                if Draft.eq localDraft expectedDraft then
                    [ overwriteLocalDraft
                    , overwriteExpectedDraft
                    ]

                else
                    []

            ( Just (Just localDraft), Just (Just expectedDraft), Just actualDraft ) ->
                if Draft.eq localDraft expectedDraft then
                    [ overwriteLocalDraft
                    , overwriteExpectedDraft
                    ]

                else if Draft.eq localDraft actualDraft then
                    [ overwriteExpectedDraft ]

                else if Draft.eq expectedDraft actualDraft then
                    [ saveDraft localDraft ]

                else
                    []
