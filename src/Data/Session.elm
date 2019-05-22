module Data.Session exposing
    ( Session
    , getHighScore
    , getLevelDrafts
    , getToken
    , init
    , withCampaign
    , withCampaigns
    , withDraft
    , withDrafts
    , withHighScore
    , withLevel
    , withLevelDrafts
    , withLevels
    , withUser
    , withoutLevel
    )

import Basics.Extra exposing (flip)
import Browser.Navigation exposing (Key)
import Data.AuthorizationToken exposing (AuthorizationToken)
import Data.Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.HighScore exposing (HighScore)
import Data.Level exposing (Level)
import Data.LevelDrafts as LevelDrafts exposing (LevelDrafts)
import Data.LevelId exposing (LevelId)
import Data.RequestResult exposing (RequestResult)
import Data.User as User exposing (User)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..), WebData)
import Set


type alias Session =
    { key : Key
    , user : User
    , levels : Dict LevelId Level
    , drafts : Dict DraftId Draft
    , campaigns : Dict CampaignId Campaign
    , highScores : Dict LevelId (WebData HighScore)
    , levelDrafts : Dict LevelId (WebData LevelDrafts)
    }


init : Key -> Session
init key =
    { key = key
    , user = User.guest
    , levels = Dict.empty
    , drafts = Dict.empty
    , campaigns = Dict.empty
    , highScores = Dict.empty
    , levelDrafts = Dict.empty
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


withDrafts : List Draft -> Session -> Session
withDrafts drafts session =
    List.foldl withDraft session drafts


withDraft : Draft -> Session -> Session
withDraft draft session =
    { session
        | drafts =
            Dict.insert draft.id draft session.drafts
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
            Dict.insert request (RemoteData.fromResult result) session.highScores
    }


getHighScore : LevelId -> Session -> WebData HighScore
getHighScore levelId session =
    Dict.get levelId session.highScores
        |> Maybe.withDefault NotAsked


getToken : Session -> Maybe AuthorizationToken
getToken =
    .user >> User.getToken


getLevelDrafts : LevelId -> Session -> WebData LevelDrafts
getLevelDrafts levelId session =
    session.levelDrafts
        |> Dict.get levelId
        |> Maybe.withDefault NotAsked


withLevelDraft : LevelId -> DraftId -> Session -> Session
withLevelDraft levelId draftId session =
    let
        insertLevelDraft levelDrafts =
            levelDrafts
                |> LevelDrafts.withDraftId draftId
                |> Success
                |> flip (Dict.insert levelId) session.levelDrafts
    in
    { session
        | levelDrafts =
            case Dict.get levelId session.levelDrafts of
                Nothing ->
                    insertLevelDraft (LevelDrafts.empty levelId)

                Just NotAsked ->
                    insertLevelDraft (LevelDrafts.empty levelId)

                Just Loading ->
                    insertLevelDraft (LevelDrafts.empty levelId)

                Just (Failure _) ->
                    insertLevelDraft (LevelDrafts.empty levelId)

                Just (Success levelDrafts) ->
                    insertLevelDraft levelDrafts
    }


withLevelDrafts : LevelDrafts -> Session -> Session
withLevelDrafts levelDrafts session =
    Set.foldl (withLevelDraft levelDrafts.levelId) session levelDrafts.draftIds
