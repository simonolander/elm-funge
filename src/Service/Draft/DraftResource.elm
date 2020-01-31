module Resource.Draft.DraftResource exposing
    ( DraftResource
    , empty
    , updateDraftsByLevelIdRequests
    )

import Data.Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..))
import Resource.ModifiableResource exposing (ModifiableRemoteResource)


type alias DraftResource =
    ModifiableRemoteResource DraftId Draft { draftsByLevelIdRequests : Dict LevelId (RemoteData GetError ()) }


empty : DraftResource
empty =
    { local = Dict.empty
    , expected = Dict.empty
    , actual = Dict.empty
    , saving = Dict.empty
    , draftsByLevelIdRequests = Dict.empty
    }


updateDraftsByLevelIdRequests : Updater (Dict LevelId (RemoteData GetError ())) -> Updater DraftResource
updateDraftsByLevelIdRequests updater resource =
    { resource | draftsByLevelIdRequests = updater resource.draftsByLevelIdRequests }
