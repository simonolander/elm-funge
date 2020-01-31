module Resource.Level.LevelResource exposing
    ( LevelResource
    , empty
    , updateLevelsByCampaignIdRequests
    )

import Data.CampaignId exposing (CampaignId)
import Data.GetError exposing (GetError)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData)
import Resource.ModifiableResource exposing (ModifiableRemoteResource)
import Service.RemoteResource exposing (RemoteResource)


type alias LevelResource =
    RemoteResource LevelId
        Level
        { levelsByCampaignIdRequests : Dict LevelId (RemoteData GetError ())
        }


empty : LevelResource
empty =
    { actual = Dict.empty
    , levelsByCampaignIdRequests = Dict.empty
    }


updateLevelsByCampaignIdRequests : Updater (Dict CampaignId (RemoteData GetError ())) -> Updater ModifiableRemoteResource
updateLevelsByCampaignIdRequests updater resource =
    { resource | levelsByCampaignIdRequests = updater resource.levelsByCampaignIdRequests }
