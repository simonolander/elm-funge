module Data.BlueprintBook exposing (BlueprintBook, empty, loadFromLocalStorage, localStorageResponse, removeBlueprintIdFromLocalStorage, removeFromLocalStorage, saveToLocalStorage, withBlueprintId, withBlueprintIds, withoutBlueprintId)

import Data.BlueprintId as BlueprintId exposing (BlueprintId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Json.Decode as Decode
import Json.Decode.Extra
import Json.Encode as Encode
import Ports.LocalStorage
import Set exposing (Set)


type alias BlueprintBook =
    Set BlueprintId


empty : BlueprintBook
empty =
    Set.empty



-- LOCAL STORAGE


localStorageKey : Ports.LocalStorage.Key
localStorageKey =
    "blueprintBook"


saveToLocalStorage : BlueprintId -> Cmd msg
saveToLocalStorage blueprintId =
    Ports.LocalStorage.storagePushToSet ( localStorageKey, BlueprintId.encode blueprintId )


loadFromLocalStorage : Cmd msg
loadFromLocalStorage =
    Ports.LocalStorage.storageGetItem localStorageKey


removeFromLocalStorage : Cmd msg
removeFromLocalStorage =
    Ports.LocalStorage.storageRemoveItem localStorageKey


removeBlueprintIdFromLocalStorage : BlueprintId -> Cmd msg
removeBlueprintIdFromLocalStorage blueprintId =
    Ports.LocalStorage.storageRemoveFromSet ( localStorageKey, BlueprintId.encode blueprintId )


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult () Decode.Error BlueprintBook)
localStorageResponse ( key, value ) =
    if key == localStorageKey then
        let
            decoder =
                Json.Decode.Extra.set BlueprintId.decoder
                    |> Decode.nullable
                    |> Decode.map (Maybe.withDefault empty)
        in
        Decode.decodeValue decoder value
            |> RequestResult.constructor ()
            |> Just

    else
        Nothing
