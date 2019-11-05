module Update.Update exposing (update)

import Data.Session exposing (Session)
import Update.Blueprint exposing (gotDeleteBlueprintResponse, gotLoadBlueprintResponse, gotLoadBlueprintsResponse, gotSaveBlueprintResponse)
import Update.Draft exposing (gotDeleteDraftResponse, gotLoadDraftResponse, gotLoadDraftsByLevelIdResponse, gotSaveDraftResponse)
import Update.HighScore exposing (gotLoadHighScoreByLevelIdResponse)
import Update.Level exposing (gotLoadLevelResponse, gotLoadLevelsByCampaignIdResponse)
import Update.SessionMsg exposing (SessionMsg(..))
import Update.Solution exposing (gotLoadSolutionResponse, gotLoadSolutionsByLevelIdResponse, gotLoadSolutionsByLevelIdsResponse, gotSaveSolutionResponse, saveSolution)
import Update.UserInfo exposing (gotLoadUserInfoResponse)


update : SessionMsg -> Session -> ( Session, Cmd SessionMsg )
update msg =
    case msg of
        GeneratedSolution solution ->
            saveSolution solution

        GotDeleteDraftResponse draftId maybeError ->
            gotDeleteDraftResponse draftId maybeError

        GotLoadDraftByDraftIdResponse draftId result ->
            gotLoadDraftResponse draftId result

        GotLoadDraftsByLevelIdResponse levelId result ->
            gotLoadDraftsByLevelIdResponse levelId result

        GotLoadHighScoreResponse levelId result ->
            gotLoadHighScoreByLevelIdResponse levelId result

        GotLoadLevelByLevelIdResponse levelId result ->
            gotLoadLevelResponse levelId result

        GotLoadLevelsByCampaignIdResponse campaignId result ->
            gotLoadLevelsByCampaignIdResponse campaignId result

        GotLoadBlueprintResponse blueprintId result ->
            gotLoadBlueprintResponse blueprintId result

        GotLoadBlueprintsResponse result ->
            gotLoadBlueprintsResponse result

        GotLoadSolutionsByLevelIdResponse levelId result ->
            gotLoadSolutionsByLevelIdResponse levelId result

        GotLoadSolutionsByLevelIdsResponse list result ->
            gotLoadSolutionsByLevelIdsResponse list result

        GotLoadSolutionsBySolutionIdResponse solutionId result ->
            gotLoadSolutionResponse solutionId result

        GotSaveDraftResponse draft maybeError ->
            gotSaveDraftResponse draft maybeError

        GotDeleteBlueprintResponse blueprintId maybeError ->
            gotDeleteBlueprintResponse blueprintId maybeError

        GotSaveBlueprintResponse blueprint maybeError ->
            gotSaveBlueprintResponse blueprint maybeError

        GotSaveSolutionResponse solution maybeError ->
            gotSaveSolutionResponse solution maybeError

        GotLoadUserInfoResponse result ->
            gotLoadUserInfoResponse result
