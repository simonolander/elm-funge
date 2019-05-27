module Data.Session exposing
    ( Session
    , campaignError
    , campaignLoading
    , draftBookError
    , draftBookLoading
    , draftError
    , draftLoading
    , getCampaign
    , getDraft
    , getDraftBook
    , getHighScore
    , getLevel
    , getSolution
    , getSolutionBook
    , getToken
    , highScoreError
    , highScoreLoading
    , init
    , levelError
    , levelLoading
    , loadingHighScore
    , setCampaignCache
    , setDraftBookCache
    , setDraftCache
    , setHighScoreCache
    , setLevelCache
    , setSolutionBookCache
    , setSolutionCache
    , solutionBookError
    , solutionBookLoading
    , solutionError
    , solutionLoading
    , withCampaign
    , withCampaigns
    , withDraft
    , withDraftBook
    , withDrafts
    , withHighScore
    , withHighScoreResult
    , withLevel
    , withLevels
    , withSolution
    , withSolutionBook
    , withSolutions
    , withUser
    , withoutLevel
    )

import Browser.Navigation exposing (Key)
import Data.AuthorizationToken exposing (AuthorizationToken)
import Data.Cache as Cache exposing (Cache)
import Data.Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId exposing (DraftId)
import Data.HighScore exposing (HighScore)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RequestResult exposing (RequestResult)
import Data.Solution exposing (Solution)
import Data.SolutionBook as SolutionBook exposing (SolutionBook)
import Data.SolutionId exposing (SolutionId)
import Data.User as User exposing (User)
import Http
import RemoteData exposing (RemoteData(..), WebData)


type alias Session =
    { key : Key
    , user : User
    , levels : Cache LevelId Level
    , drafts : Cache DraftId Draft
    , solutions : Cache SolutionId Solution
    , campaigns : Cache CampaignId Campaign
    , highScores : Cache LevelId HighScore
    , draftBooks : Cache LevelId DraftBook
    , solutionBooks : Cache LevelId SolutionBook
    }


init : Key -> Session
init key =
    { key = key
    , user = User.guest
    , levels = Cache.empty
    , drafts = Cache.empty
    , solutions = Cache.empty
    , campaigns = Cache.empty
    , highScores = Cache.empty
    , draftBooks = Cache.empty
    , solutionBooks = Cache.empty
    }


withUser : User -> Session -> Session
withUser user session =
    { session
        | user = user
    }


getToken : Session -> Maybe AuthorizationToken
getToken =
    .user >> User.getToken



-- LEVEL CACHE


setLevelCache : Session -> Cache LevelId Level -> Session
setLevelCache session cache =
    { session | levels = cache }


getLevel : LevelId -> Session -> WebData Level
getLevel levelId session =
    Cache.get levelId session.levels


withLevel : Level -> Session -> Session
withLevel level session =
    session.levels
        |> Cache.insert level.id level
        |> setLevelCache session


withLevels : List Level -> Session -> Session
withLevels levels session =
    List.foldl withLevel session levels


withoutLevel : LevelId -> Session -> Session
withoutLevel levelId session =
    session.levels
        |> Cache.remove levelId
        |> setLevelCache session


levelLoading : LevelId -> Session -> Session
levelLoading levelId session =
    session.levels
        |> Cache.loading levelId
        |> setLevelCache session


levelError : LevelId -> Http.Error -> Session -> Session
levelError levelId error session =
    session.levels
        |> Cache.failure levelId error
        |> setLevelCache session



-- DRAFT CACHE


setDraftCache : Session -> Cache LevelId Draft -> Session
setDraftCache session cache =
    { session | drafts = cache }


getDraft : LevelId -> Session -> WebData Draft
getDraft levelId session =
    Cache.get levelId session.drafts


withDraft : Draft -> Session -> Session
withDraft draft session =
    { session
        | drafts =
            session.drafts
                |> Cache.insert draft.id draft
        , draftBooks =
            session.draftBooks
                |> Cache.withDefault draft.levelId (DraftBook.empty draft.levelId)
                |> Cache.map draft.levelId (DraftBook.withDraftId draft.id)
    }


withDrafts : List Draft -> Session -> Session
withDrafts drafts session =
    List.foldl withDraft session drafts


draftLoading : LevelId -> Session -> Session
draftLoading levelId session =
    session.drafts
        |> Cache.loading levelId
        |> setDraftCache session


draftError : LevelId -> Http.Error -> Session -> Session
draftError levelId error session =
    session.drafts
        |> Cache.failure levelId error
        |> setDraftCache session



-- SOLUTION CACHE


setSolutionCache : Session -> Cache LevelId Solution -> Session
setSolutionCache session cache =
    { session | solutions = cache }


getSolution : LevelId -> Session -> WebData Solution
getSolution levelId session =
    Cache.get levelId session.solutions


withSolution : Solution -> Session -> Session
withSolution solution session =
    { session
        | solutions =
            session.solutions
                |> Cache.insert solution.id solution
        , solutionBooks =
            session.solutionBooks
                |> Cache.withDefault solution.levelId (SolutionBook.empty solution.levelId)
                |> Cache.map solution.levelId (SolutionBook.withSolutionId solution.id)
    }


withSolutions : List Solution -> Session -> Session
withSolutions solutions session =
    List.foldl withSolution session solutions


solutionLoading : LevelId -> Session -> Session
solutionLoading levelId session =
    session.solutions
        |> Cache.loading levelId
        |> setSolutionCache session


solutionError : LevelId -> Http.Error -> Session -> Session
solutionError levelId error session =
    session.solutions
        |> Cache.failure levelId error
        |> setSolutionCache session



-- CAMPAIGN CACHE


setCampaignCache : Session -> Cache LevelId Campaign -> Session
setCampaignCache session cache =
    { session | campaigns = cache }


getCampaign : LevelId -> Session -> WebData Campaign
getCampaign levelId session =
    Cache.get levelId session.campaigns


withCampaigns : List Campaign -> Session -> Session
withCampaigns campaigns session =
    List.foldl withCampaign session campaigns


withCampaign : Campaign -> Session -> Session
withCampaign campaign session =
    session.campaigns
        |> Cache.insert campaign.id campaign
        |> setCampaignCache session


campaignLoading : LevelId -> Session -> Session
campaignLoading levelId session =
    session.campaigns
        |> Cache.loading levelId
        |> setCampaignCache session


campaignError : LevelId -> Http.Error -> Session -> Session
campaignError levelId error session =
    session.campaigns
        |> Cache.failure levelId error
        |> setCampaignCache session



-- HIGH SCORE CACHE


setHighScoreCache : Session -> Cache LevelId HighScore -> Session
setHighScoreCache session cache =
    { session | highScores = cache }


getHighScore : LevelId -> Session -> WebData HighScore
getHighScore levelId session =
    Cache.get levelId session.highScores


withHighScore : HighScore -> Session -> Session
withHighScore highScore session =
    session.highScores
        |> Cache.insert highScore.levelId highScore
        |> setHighScoreCache session


withHighScoreResult : RequestResult LevelId HighScore -> Session -> Session
withHighScoreResult { request, result } session =
    { session
        | highScores =
            Cache.fromResult request result session.highScores
    }


highScoreLoading : LevelId -> Session -> Session
highScoreLoading levelId session =
    session.highScores
        |> Cache.loading levelId
        |> setHighScoreCache session


highScoreError : LevelId -> Http.Error -> Session -> Session
highScoreError levelId error session =
    session.highScores
        |> Cache.failure levelId error
        |> setHighScoreCache session



-- DRAFT BOOK CACHE


setDraftBookCache : Session -> Cache LevelId DraftBook -> Session
setDraftBookCache session cache =
    { session | draftBooks = cache }


getDraftBook : LevelId -> Session -> WebData DraftBook
getDraftBook levelId session =
    Cache.get levelId session.draftBooks


withDraftBook : DraftBook -> Session -> Session
withDraftBook draftBook session =
    session.draftBooks
        |> Cache.withDefault draftBook.levelId draftBook
        |> Cache.map draftBook.levelId (DraftBook.withDraftIds draftBook.draftIds)
        |> setDraftBookCache session


draftBookLoading : LevelId -> Session -> Session
draftBookLoading levelId session =
    session.draftBooks
        |> Cache.loading levelId
        |> setDraftBookCache session


draftBookError : LevelId -> Http.Error -> Session -> Session
draftBookError levelId error session =
    session.draftBooks
        |> Cache.failure levelId error
        |> setDraftBookCache session


loadingHighScore : LevelId -> Session -> Session
loadingHighScore levelId session =
    { session
        | highScores =
            Cache.loading levelId session.highScores
    }



-- SOLUTION BOOK CACHE


setSolutionBookCache : Session -> Cache LevelId SolutionBook -> Session
setSolutionBookCache session cache =
    { session | solutionBooks = cache }


getSolutionBook : LevelId -> Session -> WebData SolutionBook
getSolutionBook levelId session =
    Cache.get levelId session.solutionBooks


withSolutionBook : SolutionBook -> Session -> Session
withSolutionBook solutionBook session =
    session.solutionBooks
        |> Cache.withDefault solutionBook.levelId solutionBook
        |> Cache.map solutionBook.levelId (SolutionBook.withSolutionIds solutionBook.solutionIds)
        |> setSolutionBookCache session


solutionBookLoading : LevelId -> Session -> Session
solutionBookLoading levelId session =
    session.solutionBooks
        |> Cache.loading levelId
        |> setSolutionBookCache session


solutionBookError : LevelId -> Http.Error -> Session -> Session
solutionBookError levelId error session =
    session.solutionBooks
        |> Cache.failure levelId error
        |> setSolutionBookCache session
