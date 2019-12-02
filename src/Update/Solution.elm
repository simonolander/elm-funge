module Update.Solution exposing
    ( getSolutionsByLevelId
    , getSolutionsByLevelIds
    , gotLoadSolutionResponse
    , gotLoadSolutionsByLevelIdResponse
    , gotLoadSolutionsByLevelIdsResponse
    , gotSaveSolutionResponse
    , loadSolution
    , loadSolutionsByCampaignIdsResponse
    , loadSolutionsByLevelIdResponse
    , loadSolutionsByLevelIdsResponse
    , loadSolutionsBySolutionIds
    , saveSolution
    )

import Data.CampaignId exposing (CampaignId)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.Session exposing (Session)
import Data.Solution exposing (Solution)
import Data.SolutionId exposing (SolutionId)
import Data.SubmitSolutionError exposing (SubmitSolutionError)
import Debug exposing (todo)
import RemoteData exposing (RemoteData)
import Update.SessionMsg exposing (SessionMsg)



-- LOAD


loadSolution : SolutionId -> CmdUpdater Session SessionMsg
loadSolution solutionId session =
    todo ""


loadSolutionsBySolutionIds : List SolutionId -> CmdUpdater Session SessionMsg
loadSolutionsBySolutionIds solutionIds =
    CmdUpdater.batch (List.map loadSolution solutionIds)


loadSolutionsByLevelIdResponse : LevelId -> CmdUpdater Session SessionMsg
loadSolutionsByLevelIdResponse levelId session =
    todo ""


loadSolutionsByLevelIdsResponse : List LevelId -> CmdUpdater Session SessionMsg
loadSolutionsByLevelIdsResponse levelIds session =
    todo ""


loadSolutionsByCampaignId : CampaignId -> CmdUpdater Session SessionMsg
loadSolutionsByCampaignId campaignId session =
    todo ""


loadSolutionsByCampaignIdsResponse : List CampaignId -> CmdUpdater Session SessionMsg
loadSolutionsByCampaignIdsResponse campaignIds session =
    todo ""


gotLoadSolutionResponse : SolutionId -> Result GetError (Maybe Solution) -> CmdUpdater Session SessionMsg
gotLoadSolutionResponse solutionId result session =
    todo ""


gotLoadSolutionsByLevelIdResponse : LevelId -> Result GetError (List Solution) -> CmdUpdater Session SessionMsg
gotLoadSolutionsByLevelIdResponse levelId result session =
    todo ""


gotLoadSolutionsByLevelIdsResponse : List LevelId -> Result GetError (List Solution) -> CmdUpdater Session SessionMsg
gotLoadSolutionsByLevelIdsResponse levelIds result session =
    todo ""



-- GETTERS


getSolutionsByLevelId : LevelId -> Session -> RemoteData GetError (List Solution)
getSolutionsByLevelId levelId session =
    todo ""


getSolutionsByLevelIds : List LevelId -> Session -> RemoteData GetError (List Solution)
getSolutionsByLevelIds levelIds session =
    todo ""



-- SAVE


saveSolution : Solution -> CmdUpdater Session SessionMsg
saveSolution solution session =
    todo ""


gotSaveSolutionResponse : Solution -> Maybe SubmitSolutionError -> CmdUpdater Session SessionMsg
gotSaveSolutionResponse solution maybeError session =
    todo ""



-- PRIVATE


gotSolution : SolutionId -> Maybe Solution -> CmdUpdater Session SessionMsg
gotSolution solutionId maybeSolution session =
    todo ""
