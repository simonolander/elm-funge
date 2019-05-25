module Data.Session exposing
    ( Session
    , getDraft
    , getDraftBook
    , getHighScore
    , getToken
    , init
    , loadingDraftBook
    , loadingHighScore
    , withCampaign
    , withCampaigns
    , withDraft
    , withDraftBook
    , withDrafts
    , withHighScore
    , withLevel
    , withLevels
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
import Data.User as User exposing (User)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..), WebData)


type alias Session =
    { key : Key
    , user : User
    , levels : Dict LevelId Level
    , drafts : Dict DraftId Draft
    , campaigns : Dict CampaignId Campaign
    , highScores : Cache LevelId HighScore
    , draftBooks : Cache LevelId DraftBook
    }


init : Key -> Session
init key =
    { key = key
    , user = User.guest
    , levels = Dict.empty
    , drafts = Dict.empty
    , campaigns = Dict.empty
    , highScores = Cache.empty
    , draftBooks = Cache.empty
    }


withUser : User -> Session -> Session
withUser user session =
    { session
        | user = user
    }


withLevels : List Level -> Session -> Session
withLevels levels session =
    List.foldl withLevel session levels


withLevel : Level -> Session -> Session
withLevel level session =
    { session
        | levels =
            Dict.insert level.id level session.levels
    }


withoutLevel : LevelId -> Session -> Session
withoutLevel levelId session =
    { session
        | levels =
            Dict.remove levelId session.levels
    }


getDraft : DraftId -> Session -> WebData Draft
getDraft draftId session =
    case Dict.get draftId session.drafts of
        Just draft ->
            Success draft

        -- TODO
        Nothing ->
            Loading


withDrafts : List Draft -> Session -> Session
withDrafts drafts session =
    List.foldl withDraft session drafts


withDraft : Draft -> Session -> Session
withDraft draft session =
    { session
        | drafts =
            Dict.insert draft.id draft session.drafts
        , draftBooks =
            session.draftBooks
                |> Cache.withDefault draft.levelId (DraftBook.empty draft.levelId)
                |> Cache.map draft.levelId (DraftBook.withDraftId draft.id)
    }


withCampaign : Campaign -> Session -> Session
withCampaign campaign session =
    { session
        | campaigns =
            Dict.insert campaign.id campaign session.campaigns
    }


withCampaigns : List Campaign -> Session -> Session
withCampaigns campaigns session =
    List.foldl withCampaign session campaigns


withHighScore : RequestResult LevelId HighScore -> Session -> Session
withHighScore { request, result } session =
    { session
        | highScores =
            Cache.fromResult request result session.highScores
    }


getHighScore : LevelId -> Session -> WebData HighScore
getHighScore levelId session =
    Cache.get levelId session.highScores


getToken : Session -> Maybe AuthorizationToken
getToken =
    .user >> User.getToken


getDraftBook : LevelId -> Session -> WebData DraftBook
getDraftBook levelId session =
    Cache.get levelId session.draftBooks


withDraftBook : DraftBook -> Session -> Session
withDraftBook draftBook session =
    { session
        | draftBooks =
            session.draftBooks
                |> Cache.withDefault draftBook.levelId draftBook
                |> Cache.map draftBook.levelId (DraftBook.withDraftIds draftBook.draftIds)
    }


loadingDraftBook : LevelId -> Session -> Session
loadingDraftBook levelId session =
    { session
        | draftBooks =
            Cache.loading levelId session.draftBooks
    }


loadingHighScore : LevelId -> Session -> Session
loadingHighScore levelId session =
    { session
        | highScores =
            Cache.loading levelId session.highScores
    }
