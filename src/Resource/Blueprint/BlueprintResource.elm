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
import RemoteData exposing (RemoteData(..))
import Resource.Resource as Resource exposing (Resource)


type alias BlueprintResource =
    Resource BlueprintId Blueprint { loadAllBlueprintsRemoteData : Maybe (RemoteData GetError (List Blueprint)) }



-- INIT


empty : BlueprintResource
empty =
    let
        a =
            Resource.empty
    in
    { a | loadAllBlueprintsRemoteData = Nothing }



-- SETTER


withLoadAllBlueprintsRemoteData : Maybe (RemoteData GetError (List Blueprint)) -> Updater BlueprintResource
withLoadAllBlueprintsRemoteData loadAllBlueprintsRemoteData blueprintResource =
    { blueprintResource | loadAllBlueprintsRemoteData = loadAllBlueprintsRemoteData }



-- UPDATE


updateLoadAllBlueprintsRemoteData : Updater (Maybe (RemoteData GetError (List Blueprint))) -> Updater BlueprintResource
updateLoadAllBlueprintsRemoteData update resource =
    { resource | loadAllBlueprintsRemoteData = update resource.loadAllBlueprintsRemoteData }
