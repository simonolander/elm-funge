module Update.Update exposing (update)

import Basics.Extra exposing (flip)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, andThen)
import Data.GetError as GetError exposing (GetError)
import Data.Session as Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Ports.Console as Console
import Update.Draft exposing (gotDeleteDraftResponse, gotLoadDraftResponse, gotLoadDraftsByLevelIdResponse, gotSaveDraftResponse)
import Update.HighScore exposing (gotLoadHighScoreByLevelIdResponse)
import Update.Level exposing (gotLoadLevelResponse, gotLoadLevelsByCampaignIdResponse)
import Update.SessionMsg exposing (SessionMsg(..))
import Update.Solution exposing (gotLoadSolutionResponse, gotLoadSolutionsByLevelIdResponse, gotLoadSolutionsByLevelIdsResponse, gotSaveSolutionResponse, saveSolution)
import Update.UserInfo exposing (gotLoadUserInfoResponse)


update : SessionMsg -> CmdUpdater Session SessionMsg
update msg session =
    flip CmdUpdater.batch session <|
        case msg of
            GeneratedSolution solution ->
                --TODO Also save solution to high scores
                --Cache.update
                --    solution.levelId
                --    (RemoteData.withDefault (HighScore.empty solution.levelId) >> HighScore.withScore solution.score >> RemoteData.Success)
                --    session.highScores
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
                gotLoadBlueprintByBlueprintIdResponse session.accessToken blueprintId result
                    |> Session.updateBlueprints

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

            GotLoadUserInfoResponse accessToken result ->
                gotLoadUserInfoResponse accessToken result


gotGetResult : Result GetError a -> CmdUpdater Session SessionMsg
gotGetResult result session =
    case result of
        Err (GetError.InvalidAccessToken error) ->
            ( Session.updateAccessToken VerifiedAccessToken.invalidate session
            , Console.errorString error
            )

        _ ->
            ( session, Cmd.none )
