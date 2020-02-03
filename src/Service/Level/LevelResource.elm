module Service.Level.LevelResource exposing
    ( LevelResource
    , empty
    , updateLevelsByCampaignIdRequests
    )

import Data.CampaignId exposing (CampaignId)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import Service.RemoteRequestDict exposing (RemoteRequestDict)
import Service.RemoteResource exposing (RemoteResource)


type alias LevelResource =
    RemoteResource LevelId
        Level
        { levelsByCampaignIdRequests : RemoteRequestDict CampaignId
        }


empty : LevelResource
empty =
    { actual = Dict.empty
    , levelsByCampaignIdRequests = Dict.empty
    }


updateLevelsByCampaignIdRequests : Updater (RemoteRequestDict CampaignId) -> Updater LevelResource
updateLevelsByCampaignIdRequests updater resource =
    { resource | levelsByCampaignIdRequests = updater resource.levelsByCampaignIdRequests }
