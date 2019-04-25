module Data.Session exposing
    ( Session
    , getDraftAndLevel
    , getLevelDrafts
    , getToken
    , init
    , withCampaign
    , withCampaigns
    , withDraft
    , withDrafts
    , withLevel
    , withLevels
    , withUser
    , withoutLevel
    )

import Browser.Navigation exposing (Key)
import Data.AuthorizationToken exposing (AuthorizationToken)
import Data.Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.User as User exposing (User)
import Dict exposing (Dict)


type alias Session =
    { key : Key
    , user : User
    , levels : Dict LevelId Level
    , drafts : Dict DraftId Draft
    , campaigns : Dict CampaignId Campaign
    }


init : Key -> Session
init key =
    { key = key
    , user = User.guest
    , levels = Dict.empty
    , drafts = Dict.empty
    , campaigns = Dict.empty
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


getToken : Session -> Maybe AuthorizationToken
getToken =
    .user >> User.getToken


getLevelDrafts : LevelId -> Session -> List Draft
getLevelDrafts levelId session =
    session.drafts
        |> Dict.values
        |> List.filter (\draft -> draft.levelId == levelId)


getDraftAndLevel : DraftId -> Session -> Maybe ( Draft, Level )
getDraftAndLevel draftId session =
    case Dict.get draftId session.drafts of
        Just draft ->
            case Dict.get draft.levelId session.levels of
                Just level ->
                    Just ( draft, level )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing
