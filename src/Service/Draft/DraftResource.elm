module Service.Draft.DraftResource exposing
    ( DraftResource
    , empty
    , updateDraftsByLevelIdRequests
    )

import Data.Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.LevelId exposing (LevelId)
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import Service.ModifiableRemoteResource exposing (ModifiableRemoteResource)
import Service.RemoteRequestDict exposing (RemoteRequestDict)


type alias DraftResource =
    ModifiableRemoteResource DraftId Draft { draftsByLevelIdRequests : RemoteRequestDict LevelId }


empty : DraftResource
empty =
    { local = Dict.empty
    , expected = Dict.empty
    , actual = Dict.empty
    , saving = Dict.empty
    , draftsByLevelIdRequests = Dict.empty
    }


updateDraftsByLevelIdRequests : Updater (RemoteRequestDict LevelId) -> Updater DraftResource
updateDraftsByLevelIdRequests updater resource =
    { resource | draftsByLevelIdRequests = updater resource.draftsByLevelIdRequests }
