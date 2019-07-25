module Data.Session exposing
    ( Session
    , campaignError
    , campaignLoading
    , draftBookError
    , draftBookLoading
    , getAccessToken
    , getCampaign
    , getDraftBook
    , getHighScore
    , getLevel
    , getSolution
    , getSolutionBook
    , highScoreError
    , highScoreLoading
    , init
    , levelError
    , levelLoading
    , loadingHighScore
    , setCampaignCache
    , setDraftBookCache
    , setHighScoreCache
    , setLevelCache
    , setSolutionBookCache
    , setSolutionCache
    , solutionBookError
    , solutionBookLoading
    , solutionError
    , solutionLoading
    , withCampaign
    , withCampaignCache
    , withCampaigns
    , withDraftBook
    , withDraftBookCache
    , withDraftCache
    , withHighScore
    , withHighScoreCache
    , withHighScoreResult
    , withLevel
    , withLevelCache
    , withLevels
    , withSolution
    , withSolutionBook
    , withSolutionBookCache
    , withSolutionCache
    , withSolutions
    , withUrl
    , withUser
    , withoutLevel
    )

import Browser.Navigation exposing (Key)
import Data.AccessToken exposing (AccessToken)
import Data.Cache as Cache exposing (Cache)
import Data.Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.DetailedHttpError exposing (DetailedHttpError)
import Data.Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId exposing (DraftId)
import Data.HighScore exposing (HighScore)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache exposing (RemoteCache)
import Data.RequestResult exposing (RequestResult)
import Data.Solution exposing (Solution)
import Data.SolutionBook as SolutionBook exposing (SolutionBook)
import Data.SolutionId exposing (SolutionId)
import Data.User as User exposing (User)
import RemoteData exposing (RemoteData(..))
import Url exposing (Url)


type alias Session =
    { key : Key
    , url : Url
    , user : User
    , levels : Cache LevelId Level
    , drafts : RemoteCache DraftId Draft
    , solutions : Cache SolutionId Solution
    , campaigns : Cache CampaignId Campaign
    , highScores : Cache LevelId HighScore
    , draftBooks : Cache LevelId DraftBook
    , solutionBooks : Cache LevelId SolutionBook
    }


init : Key -> Url -> Session
init key url =
    { key = key
    , url = url
    , user = User.guest
    , levels = Cache.empty
    , drafts = RemoteCache.empty
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


getAccessToken : Session -> Maybe AccessToken
getAccessToken =
    .user >> User.getToken


withUrl : Url -> Session -> Session
withUrl url session =
    { session | url = url }


withLevelCache : Cache LevelId Level -> Session -> Session
withLevelCache cache session =
    { session | levels = cache }


withDraftCache : RemoteCache DraftId Draft -> Session -> Session
withDraftCache cache session =
    { session | drafts = cache }


withSolutionCache : Cache SolutionId Solution -> Session -> Session
withSolutionCache cache session =
    { session | solutions = cache }


withCampaignCache : Cache CampaignId Campaign -> Session -> Session
withCampaignCache cache session =
    { session | campaigns = cache }


withHighScoreCache : Cache LevelId HighScore -> Session -> Session
withHighScoreCache cache session =
    { session | highScores = cache }


withDraftBookCache : Cache LevelId DraftBook -> Session -> Session
withDraftBookCache cache session =
    { session | draftBooks = cache }


withSolutionBookCache : Cache LevelId SolutionBook -> Session -> Session
withSolutionBookCache cache session =
    { session | solutionBooks = cache }



-- LEVEL CACHE


setLevelCache : Session -> Cache LevelId Level -> Session
setLevelCache session cache =
    { session | levels = cache }


getLevel : LevelId -> Session -> RemoteData DetailedHttpError Level
getLevel levelId session =
    Cache.get levelId session.levels


withLevel : Level -> Session -> Session
withLevel level session =
    session.levels
        |> Cache.withValue level.id level
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


levelError : LevelId -> DetailedHttpError -> Session -> Session
levelError levelId error session =
    session.levels
        |> Cache.withError levelId error
        |> setLevelCache session



-- SOLUTION CACHE


setSolutionCache : Session -> Cache LevelId Solution -> Session
setSolutionCache session cache =
    { session | solutions = cache }


getSolution : LevelId -> Session -> RemoteData DetailedHttpError Solution
getSolution levelId session =
    Cache.get levelId session.solutions


withSolution : Solution -> Session -> Session
withSolution solution session =
    { session
        | solutions =
            session.solutions
                |> Cache.withValue solution.id solution
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


solutionError : LevelId -> DetailedHttpError -> Session -> Session
solutionError levelId error session =
    session.solutions
        |> Cache.withError levelId error
        |> setSolutionCache session



-- CAMPAIGN CACHE


setCampaignCache : Session -> Cache CampaignId Campaign -> Session
setCampaignCache session cache =
    { session | campaigns = cache }


getCampaign : CampaignId -> Session -> RemoteData DetailedHttpError Campaign
getCampaign campaignId session =
    Cache.get campaignId session.campaigns


withCampaigns : List Campaign -> Session -> Session
withCampaigns campaigns session =
    List.foldl withCampaign session campaigns


withCampaign : Campaign -> Session -> Session
withCampaign campaign session =
    session.campaigns
        |> Cache.withValue campaign.id campaign
        |> setCampaignCache session


campaignLoading : CampaignId -> Session -> Session
campaignLoading campaignId session =
    session.campaigns
        |> Cache.loading campaignId
        |> setCampaignCache session


campaignError : CampaignId -> DetailedHttpError -> Session -> Session
campaignError campaignId error session =
    session.campaigns
        |> Cache.withError campaignId error
        |> setCampaignCache session



-- HIGH SCORE CACHE


setHighScoreCache : Session -> Cache LevelId HighScore -> Session
setHighScoreCache session cache =
    { session | highScores = cache }


getHighScore : LevelId -> Session -> RemoteData DetailedHttpError HighScore
getHighScore levelId session =
    Cache.get levelId session.highScores


withHighScore : HighScore -> Session -> Session
withHighScore highScore session =
    session.highScores
        |> Cache.withValue highScore.levelId highScore
        |> setHighScoreCache session


withHighScoreResult : RequestResult LevelId DetailedHttpError HighScore -> Session -> Session
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


highScoreError : LevelId -> DetailedHttpError -> Session -> Session
highScoreError levelId error session =
    session.highScores
        |> Cache.withError levelId error
        |> setHighScoreCache session



-- DRAFT BOOK CACHE


setDraftBookCache : Session -> Cache LevelId DraftBook -> Session
setDraftBookCache session cache =
    { session | draftBooks = cache }


getDraftBook : LevelId -> Session -> RemoteData DetailedHttpError DraftBook
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


draftBookError : LevelId -> DetailedHttpError -> Session -> Session
draftBookError levelId error session =
    session.draftBooks
        |> Cache.withError levelId error
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


getSolutionBook : LevelId -> Session -> RemoteData DetailedHttpError SolutionBook
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


solutionBookError : LevelId -> DetailedHttpError -> Session -> Session
solutionBookError levelId error session =
    session.solutionBooks
        |> Cache.withError levelId error
        |> setSolutionBookCache session
