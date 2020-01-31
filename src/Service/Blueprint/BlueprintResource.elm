module Resource.Blueprint.BlueprintResource exposing
    ( BlueprintResource
    , empty
    , updateLoadAllBlueprintsRemoteData
    , withLoadAllBlueprintsRemoteData
    )

import Data.Blueprint exposing (Blueprint)
import Data.BlueprintId exposing (BlueprintId)
import Data.GetError exposing (GetError)
import Data.Updater exposing (Updater)
import Dict
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Resource.ModifiableResource exposing (ModifiableRemoteResource)


type alias BlueprintResource =
    ModifiableRemoteResource BlueprintId Blueprint { loadAllBlueprintsRemoteData : RemoteData GetError () }



-- INIT


empty : BlueprintResource
empty =
    { local = Dict.empty
    , expected = Dict.empty
    , actual = Dict.empty
    , saving = Dict.empty
    , loadAllBlueprintsRemoteData = NotAsked
    }


getAllBlueprintsForUser : BlueprintResource -> RemoteData GetError (List Blueprint)
getAllBlueprintsForUser resource =
    resource.loadAllBlueprintsRemoteData
        |> RemoteData.map
            (Dict.values resource.local
                |> Maybe.Extra.values
                |> always
            )



-- SETTER


withLoadAllBlueprintsRemoteData : RemoteData GetError () -> Updater BlueprintResource
withLoadAllBlueprintsRemoteData loadAllBlueprintsRemoteData blueprintResource =
    { blueprintResource | loadAllBlueprintsRemoteData = loadAllBlueprintsRemoteData }



-- UPDATE


updateLoadAllBlueprintsRemoteData : Updater (RemoteData GetError ()) -> Updater BlueprintResource
updateLoadAllBlueprintsRemoteData update resource =
    { resource | loadAllBlueprintsRemoteData = update resource.loadAllBlueprintsRemoteData }
