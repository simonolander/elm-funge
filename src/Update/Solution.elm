module Update.Solution exposing
    ( gotLoadSolutionResponse
    , gotLoadSolutionsByLevelIdResponse
    , gotLoadSolutionsByLevelIdsResponse
    , gotSaveSolutionResponse
    , loadSolution
    , loadSolutionsByCampaignIdsResponse
    , loadSolutionsByLevelIdResponse
    , loadSolutionsByLevelIdsResponse
    , saveSolution
    )

import Data.CampaignId exposing (CampaignId)
import Data.GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.Session exposing (Session)
import Data.Solution exposing (Solution)
import Data.SolutionId exposing (SolutionId)
import Data.SubmitSolutionError exposing (SubmitSolutionError)
import Debug exposing (todo)
import Update.SessionMsg exposing (SessionMsg)



-- LOAD


loadSolution : SolutionId -> Session -> ( Session, Cmd SessionMsg )
loadSolution solutionId session =
    todo ""


loadSolutionsByLevelIdResponse : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionsByLevelIdResponse levelId session =
    todo ""


loadSolutionsByLevelIdsResponse : List LevelId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionsByLevelIdsResponse levelIds session =
    todo ""


loadSolutionsByCampaignId : CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionsByCampaignId campaignId session =
    todo ""


loadSolutionsByCampaignIdsResponse : List CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionsByCampaignIdsResponse campaignIds session =
    todo ""


gotLoadSolutionResponse : SolutionId -> Result GetError (Maybe Solution) -> Session -> ( Session, Cmd SessionMsg )
gotLoadSolutionResponse solutionId result session =
    todo ""


gotLoadSolutionsByLevelIdResponse : LevelId -> Result GetError (List Solution) -> Session -> ( Session, Cmd SessionMsg )
gotLoadSolutionsByLevelIdResponse levelId result session =
    todo ""


gotLoadSolutionsByLevelIdsResponse : List LevelId -> Result GetError (List Solution) -> Session -> ( Session, Cmd SessionMsg )
gotLoadSolutionsByLevelIdsResponse levelIds result session =
    todo ""



-- SAVE


saveSolution : Solution -> Session -> ( Session, Cmd SessionMsg )
saveSolution solution session =
    todo ""


gotSaveSolutionResponse : Solution -> Maybe SubmitSolutionError -> Session -> ( Session, Cmd SessionMsg )
gotSaveSolutionResponse solution maybeError session =
    todo ""



-- PRIVATE


gotSolution : SolutionId -> Maybe Solution -> Session -> ( Session, Cmd SessionMsg )
gotSolution solutionId maybeSolution session =
    todo ""
