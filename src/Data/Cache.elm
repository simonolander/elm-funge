module Data.Cache exposing (Cache, empty, fromRequestResults, fromResult, fromResultDict, fromValueDict, get, insertRequestResult, isNotAsked, keys, loading, map, remove, setInsert, values, withDefault, withError, withResult, withValue)

import Basics.Extra exposing (flip)
import Data.RequestResult exposing (RequestResult)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..))
import Set exposing (Set)


type Cache comparable error value
    = Cache (Dict comparable (RemoteData error value))


get : comparable -> Cache comparable error value -> RemoteData error value
get key cache =
    cache
        |> getDict
        |> Dict.get key
        |> Maybe.withDefault NotAsked


keys : Cache comparable error value -> List comparable
keys cache =
    cache
        |> getDict
        |> Dict.keys


values : Cache comparable error value -> List (RemoteData error value)
values cache =
    cache
        |> getDict
        |> Dict.values


empty : Cache comparable error value
empty =
    Cache Dict.empty


fromRequestResults : List (RequestResult comparable error value) -> Cache comparable error value
fromRequestResults requestResults =
    List.foldl insertRequestResult empty requestResults


fromResultDict : Dict comparable (Result error value) -> Cache comparable error value
fromResultDict dict =
    Cache (Dict.map (always RemoteData.fromResult) dict)


fromValueDict : Dict comparable value -> Cache comparable error value
fromValueDict dict =
    Cache (Dict.map (always RemoteData.succeed) dict)


insertRequestResult : RequestResult comparable error value -> Cache comparable error value -> Cache comparable error value
insertRequestResult requestResult cache =
    insertInternal requestResult.request (RemoteData.fromResult requestResult.result) cache


withValue : comparable -> value -> Cache comparable error value -> Cache comparable error value
withValue key value =
    insertInternal key (Success value)


withResult : comparable -> Result error value -> Cache comparable error value -> Cache comparable error value
withResult key result cache =
    insertInternal key (RemoteData.fromResult result) cache


remove : comparable -> Cache comparable error value -> Cache comparable error value
remove key cache =
    cache
        |> getDict
        |> Dict.remove key
        |> Cache


withError : comparable -> error -> Cache comparable error value -> Cache comparable error value
withError key error =
    insertInternal key (Failure error)


loading : comparable -> Cache comparable error value -> Cache comparable error value
loading key =
    insertInternal key Loading


isNotAsked : comparable -> Cache comparable error value -> Bool
isNotAsked key cache =
    cache
        |> get key
        |> RemoteData.isNotAsked



-- ADVANCED


fromResult : comparable -> Result error value -> Cache comparable error value -> Cache comparable error value
fromResult key result =
    insertInternal key (RemoteData.fromResult result)


setInsert : comparable1 -> comparable2 -> Cache comparable1 error (Set comparable2) -> Cache comparable1 error (Set comparable2)
setInsert key value cache =
    cache
        |> getDict
        |> Dict.get key
        |> Maybe.withDefault (Success Set.empty)
        |> RemoteData.withDefault Set.empty
        |> Set.insert value
        |> flip (withValue key) cache


withDefault : comparable -> value -> Cache comparable error value -> Cache comparable error value
withDefault key default cache =
    get key cache
        |> RemoteData.withDefault default
        |> flip (withValue key) cache


map : comparable -> (value -> value) -> Cache comparable error value -> Cache comparable error value
map key function cache =
    get key cache
        |> RemoteData.map function
        |> flip (insertInternal key) cache



-- INTERNAL


getDict : Cache comparable error value -> Dict comparable (RemoteData error value)
getDict (Cache dict) =
    dict


insertInternal : comparable -> RemoteData error value -> Cache comparable error value -> Cache comparable error value
insertInternal key webData cache =
    cache
        |> getDict
        |> Dict.insert key webData
        |> Cache
