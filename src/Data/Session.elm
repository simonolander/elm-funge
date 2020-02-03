module Data.Session exposing
    ( Drafts
    , Session
    , empty
    , getSolutionBook
    , setCampaignCache
    , updateAccessToken
    , updateBlueprints
    , updateDrafts
    , withAccessToken
    , withCampaign
    , withCampaignCache
    , withCampaigns
    , withDraftCache
    , withExpectedUserInfo
    , withHighScoreCache
    , withSolutionBookCache
    , withUrl
    )

import Browser.Navigation exposing (Key)
import Data.Cache as Cache exposing (Cache)
import Data.Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.GetError exposing (GetError)
import Data.HighScore exposing (HighScore)
import Data.LevelId exposing (LevelId)
import Data.SolutionBook exposing (SolutionBook)
import Data.Updater exposing (Updater)
import Data.UserInfo exposing (UserInfo)
import Data.VerifiedAccessToken exposing (VerifiedAccessToken(..))
import RemoteData exposing (RemoteData(..))
import Service.Blueprint.BlueprintResource as BlueprintResource exposing (BlueprintResource)
import Service.Draft.DraftResource as DraftResource exposing (DraftResource)
import Service.Level.LevelResource as LevelResource exposing (LevelResource)
import Service.Solution.SolutionResource as SolutionResource exposing (SolutionResource)
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
    , solutions : SolutionResource
    , campaigns : Cache CampaignId GetError Campaign
    , blueprints : BlueprintResource
    , highScores : Cache LevelId GetError HighScore
    , solutionBooks : Cache LevelId GetError SolutionBook
    }


empty : Key -> Url -> Session
empty key url =
    { key = key
    , url = url
    , accessToken = None
    , userInfo = Nothing
    , expectedUserInfo = Nothing
    , actualUserInfo = NotAsked
    , levels = LevelResource.empty
    , drafts = DraftResource.empty
    , solutions = SolutionResource.empty
    , campaigns = Cache.empty
    , blueprints = BlueprintResource.empty
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


withDraftCache : Drafts -> Updater Session
withDraftCache cache session =
    { session | drafts = cache }


updateDrafts : Updater Drafts -> Updater Session
updateDrafts updater session =
    { session | drafts = updater session.drafts }


updateBlueprints : Updater BlueprintResource -> Updater Session
updateBlueprints updater session =
    { session | blueprints = updater session.blueprints }


withCampaignCache : Cache CampaignId GetError Campaign -> Updater Session
withCampaignCache cache session =
    { session | campaigns = cache }


withHighScoreCache : Cache LevelId GetError HighScore -> Updater Session
withHighScoreCache cache session =
    { session | highScores = cache }


withSolutionBookCache : Cache LevelId GetError SolutionBook -> Updater Session
withSolutionBookCache cache session =
    { session | solutionBooks = cache }



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
