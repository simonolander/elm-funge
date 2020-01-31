module Data.Session exposing
    ( Drafts
    , Session
    , getLevel
    , getSolutionBook
    , init
    , setCampaignCache
    , setLevelCache
    , updateAccessToken
    , updateBlueprints
    , updateCampaignRequests
    , updateDrafts
    , updateLevels
    , updateSavingDraftRequests
    , updateSolutions
    , withAccessToken
    , withCampaign
    , withCampaignCache
    , withCampaigns
    , withDraftCache
    , withExpectedUserInfo
    , withHighScoreCache
    , withLevel
    , withLevelCache
    , withLevels
    , withSolutionBookCache
    , withSolutionCache
    , withUrl
    )

import Browser.Navigation exposing (Key)
import Data.Cache as Cache exposing (Cache)
import Data.Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.GetError exposing (GetError)
import Data.HighScore exposing (HighScore)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache exposing (RemoteCache)
import Data.SaveError exposing (SaveError)
import Data.SaveRequest exposing (SaveRequest)
import Data.Solution exposing (Solution)
import Data.SolutionBook exposing (SolutionBook)
import Data.SolutionId exposing (SolutionId)
import Data.Updater exposing (Updater)
import Data.UserInfo exposing (UserInfo)
import Data.VerifiedAccessToken exposing (VerifiedAccessToken(..))
import Dict exposing (Dict)
import Json.Encode
import RemoteData exposing (RemoteData(..))
import Resource.Blueprint.BlueprintResource as BlueprintResource exposing (BlueprintResource)
import Resource.Draft.DraftResource as DraftResource exposing (DraftResource)
import Resource.Level.LevelResource as LevelResource exposing (LevelResource)
import Url exposing (Url)


type alias Drafts =
    DraftResource


type alias Session =
    { key : Key
    , url : Url
    , accessToken : VerifiedAccessToken
    , userInfo : Maybe UserInfo
    , expectedUserInfo : Maybe UserInfo
    , actualUserInfo : RemoteData GetError UserInfo
    , levels : LevelResource
    , drafts : Drafts
    , savingDraftRequests : Dict DraftId (SaveRequest SaveError (Maybe Draft))
    , solutions : RemoteCache SolutionId (Maybe Solution)
    , campaignRequests : Cache CampaignId GetError ()
    , campaigns : Cache CampaignId GetError Campaign
    , blueprints : BlueprintResource
    , highScores : Cache LevelId GetError HighScore
    , solutionBooks : Cache LevelId GetError SolutionBook
    }


init : Key -> Url -> List ( String, Json.Encode.Value ) -> Session
init key url localStorageEntries =
    let
        ( blueprintResource, blueprintErrors ) =
            BlueprintResource.init localStorageEntries
    in
    { key = key
    , url = url
    , accessToken = None
    , userInfo = Nothing
    , expectedUserInfo = Nothing
    , actualUserInfo = NotAsked
    , levels = LevelResource.empty -- TODO init
    , drafts = DraftResource.empty
    , savingDraftRequests = Dict.empty
    , solutions = RemoteCache.empty
    , campaignRequests = Cache.empty
    , campaigns = Cache.empty
    , blueprints = blueprintResource
    , highScores = Cache.empty
    , solutionBooks = Cache.empty
    }


withUrl : Url -> Updater Session
withUrl url session =
    { session | url = url }


withExpectedUserInfo : Maybe UserInfo -> Updater Session
withExpectedUserInfo userInfo session =
    { session | expectedUserInfo = userInfo }


withAccessToken : VerifiedAccessToken -> Updater Session
withAccessToken accessToken session =
    { session | accessToken = accessToken }


updateAccessToken : Updater VerifiedAccessToken -> Updater Session
updateAccessToken function session =
    { session | accessToken = function session.accessToken }


withLevelCache : Cache LevelId GetError Level -> Updater Session
withLevelCache cache session =
    { session | levels = cache }


withDraftCache : Drafts -> Updater Session
withDraftCache cache session =
    { session | drafts = cache }


updateDrafts : Updater Drafts -> Updater Session
updateDrafts updater session =
    { session | drafts = updater session.drafts }


updateBlueprints : Updater BlueprintResource -> Updater Session
updateBlueprints updater session =
    { session | blueprints = updater session.blueprints }


updateSolutions : Updater (RemoteCache SolutionId (Maybe Solution)) -> Updater Session
updateSolutions updater session =
    { session | solutions = updater session.solutions }


withSolutionCache : RemoteCache SolutionId (Maybe Solution) -> Updater Session
withSolutionCache cache session =
    { session | solutions = cache }


withCampaignCache : Cache CampaignId GetError Campaign -> Updater Session
withCampaignCache cache session =
    { session | campaigns = cache }


withHighScoreCache : Cache LevelId GetError HighScore -> Updater Session
withHighScoreCache cache session =
    { session | highScores = cache }


withSolutionBookCache : Cache LevelId GetError SolutionBook -> Updater Session
withSolutionBookCache cache session =
    { session | solutionBooks = cache }


updateCampaignRequests : (Cache CampaignId GetError () -> Cache CampaignId GetError ()) -> Updater Session
updateCampaignRequests updater session =
    { session | campaignRequests = updater session.campaignRequests }


updateSavingDraftRequests : Updater (Dict DraftId (SaveRequest SaveError (Maybe Draft))) -> Updater Session
updateSavingDraftRequests updater session =
    { session | savingDraftRequests = updater session.savingDraftRequests }


updateLevels : Updater (Cache LevelId GetError Level) -> Updater Session
updateLevels updater session =
    { session | levels = updater session.levels }



-- LEVEL CACHE


setLevelCache : Session -> Cache LevelId GetError Level -> Session
setLevelCache session cache =
    { session | levels = cache }


getLevel : LevelId -> Session -> RemoteData GetError Level
getLevel levelId session =
    Cache.get levelId session.levels


withLevel : Level -> Updater Session
withLevel level session =
    session.levels
        |> Cache.withValue level.id level
        |> setLevelCache session


withLevels : List Level -> Updater Session
withLevels levels session =
    List.foldl withLevel session levels



-- CAMPAIGN CACHE


setCampaignCache : Session -> Cache CampaignId GetError Campaign -> Session
setCampaignCache session cache =
    { session | campaigns = cache }


withCampaigns : List Campaign -> Updater Session
withCampaigns campaigns session =
    List.foldl withCampaign session campaigns


withCampaign : Campaign -> Updater Session
withCampaign campaign session =
    session.campaigns
        |> Cache.withValue campaign.id campaign
        |> setCampaignCache session



-- SOLUTION BOOK CACHE


getSolutionBook : LevelId -> Session -> RemoteData GetError SolutionBook
getSolutionBook levelId session =
    Cache.get levelId session.solutionBooks
