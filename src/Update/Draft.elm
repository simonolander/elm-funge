module Update.Draft exposing
    ( deleteDraft
    , getDraftById
    , gotDeleteDraftResponse
    , gotLoadDraftResponse
    , gotLoadDraftsByLevelIdResponse
    , gotSaveDraftResponse
    , loadDraft
    , loadDraftsByDraftIds
    , loadDraftsByLevelId
    , saveDraft
    )

import Basics.Extra exposing (flip)
import Data.Cache as Cache
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache exposing (RemoteCache)
import Data.SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Debug exposing (todo)
import Dict
import Extra.Cmd exposing (fold)
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Update.General exposing (gotGetError)
import Update.SessionMsg exposing (SessionMsg(..))



-- LOAD DRAFT BY DRAFT ID


loadDraft : DraftId -> Session -> ( Session, Cmd SessionMsg )
loadDraft draftId session =
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


loadDraftsByDraftIds : List DraftId -> Session -> ( Session, Cmd SessionMsg )
loadDraftsByDraftIds draftIds session =
    List.map loadDraft draftIds
        |> flip fold session


gotLoadDraftResponse : DraftId -> Result GetError (Maybe Draft) -> Session -> ( Session, Cmd SessionMsg )
gotLoadDraftResponse draftId result session =
    case result of
        Ok maybeDraft ->
            gotDraft draftId maybeDraft session

        Err error ->
            Session.updateDrafts (RemoteCache.withActualError draftId error) session
                |> gotGetError error


getDraftById : DraftId -> Session -> RemoteData GetError (Maybe Draft)
getDraftById draftId session =
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


loadDraftsByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadDraftsByLevelId levelId session =
    todo ""


gotLoadDraftsByLevelIdResponse : LevelId -> Result GetError (List Draft) -> Session -> ( Session, Cmd SessionMsg )
gotLoadDraftsByLevelIdResponse levelId result session =
    todo ""



-- SAVE


saveDraft : Draft -> Session -> ( Session, Cmd SessionMsg )
saveDraft draft session =
    todo ""


gotSaveDraftResponse : Draft -> Maybe SaveError -> Session -> ( Session, Cmd SessionMsg )
gotSaveDraftResponse draft maybeError session =
    todo ""



-- DELETE


deleteDraft : DraftId -> Session -> ( Session, Cmd SessionMsg )
deleteDraft draftId session =
    todo ""


gotDeleteDraftResponse : DraftId -> Maybe SaveError -> Session -> ( Session, Cmd SessionMsg )
gotDeleteDraftResponse draftId maybeError session =
    todo ""



-- PRIVATE


gotDraft : DraftId -> Maybe Draft -> Session -> ( Session, Cmd SessionMsg )
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
