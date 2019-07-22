module Data.Cache exposing (Cache, empty, failure, fromRequestResults, fromResult, fromResultDict, get, insert, insertRequestResult, isNotAsked, keys, loading, map, remove, setInsert, withDefault)

import Basics.Extra exposing (flip)
import Data.DetailedHttpError exposing (DetailedHttpError)
import Data.RequestResult exposing (RequestResult)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..))
import Set exposing (Set)


type Cache comparable value
    = Cache (Dict comparable (RemoteData DetailedHttpError value))


get : comparable -> Cache comparable value -> RemoteData DetailedHttpError value
get key cache =
    cache
        |> getDict
        |> Dict.get key
        |> Maybe.withDefault NotAsked


keys : Cache comparable value -> List comparable
keys cache =
    cache
        |> getDict
        |> Dict.keys


empty : Cache comparable value
empty =
    Cache Dict.empty


fromRequestResults : List (RequestResult comparable DetailedHttpError value) -> Cache comparable value
fromRequestResults requestResults =
    List.foldl insertRequestResult empty requestResults


fromResultDict : Dict comparable (Result DetailedHttpError value) -> Cache comparable value
fromResultDict dict =
    Cache (Dict.map (always RemoteData.fromResult) dict)


insertRequestResult : RequestResult comparable DetailedHttpError value -> Cache comparable value -> Cache comparable value
insertRequestResult requestResult cache =
    insertInternal requestResult.request (RemoteData.fromResult requestResult.result) cache


insert : comparable -> value -> Cache comparable value -> Cache comparable value
insert key value =
    insertInternal key (Success value)


remove : comparable -> Cache comparable value -> Cache comparable value
remove key cache =
    cache
        |> getDict
        |> Dict.remove key
        |> Cache


failure : comparable -> DetailedHttpError -> Cache comparable value -> Cache comparable value
failure key error =
    insertInternal key (Failure error)


loading : comparable -> Cache comparable value -> Cache comparable value
loading key =
    insertInternal key Loading


isNotAsked : comparable -> Cache comparable value -> Bool
isNotAsked key cache =
    cache
        |> get key
        |> RemoteData.isNotAsked



-- ADVANCED


fromResult : comparable -> Result DetailedHttpError value -> Cache comparable value -> Cache comparable value
fromResult key result =
    insertInternal key (RemoteData.fromResult result)


setInsert : comparable1 -> comparable2 -> Cache comparable1 (Set comparable2) -> Cache comparable1 (Set comparable2)
setInsert key value cache =
    cache
        |> getDict
        |> Dict.get key
        |> Maybe.withDefault (Success Set.empty)
        |> RemoteData.withDefault Set.empty
        |> Set.insert value
        |> flip (insert key) cache


withDefault : comparable -> value -> Cache comparable value -> Cache comparable value
withDefault key default cache =
    get key cache
        |> RemoteData.withDefault default
        |> flip (insert key) cache


map : comparable -> (value -> value) -> Cache comparable value -> Cache comparable value
map key function cache =
    get key cache
        |> RemoteData.map function
        |> flip (insertInternal key) cache



-- INTERNAL


getDict : Cache comparable value -> Dict comparable (RemoteData DetailedHttpError value)
getDict (Cache dict) =
    dict


insertInternal : comparable -> RemoteData DetailedHttpError value -> Cache comparable value -> Cache comparable value
insertInternal key webData cache =
    cache
        |> getDict
        |> Dict.insert key webData
        |> Cache
