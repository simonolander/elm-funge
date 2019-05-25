module Data.Cache exposing (Cache, empty, error, fromResult, get, insert, loading, map, remove, setInsert, withDefault)

import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Http
import RemoteData exposing (RemoteData(..), WebData)
import Set exposing (Set)


type Cache comparable value
    = Cache (Dict comparable (WebData value))


get : comparable -> Cache comparable value -> WebData value
get key cache =
    cache
        |> getDict
        |> Dict.get key
        |> Maybe.withDefault NotAsked


empty : Cache comparable value
empty =
    Cache Dict.empty


insert : comparable -> value -> Cache comparable value -> Cache comparable value
insert key value =
    insertInternal key (Success value)


remove : comparable -> Cache comparable value -> Cache comparable value
remove key cache =
    cache
        |> getDict
        |> Dict.remove key
        |> Cache


error : comparable -> Http.Error -> Cache comparable value -> Cache comparable value
error key err =
    insertInternal key (Failure err)


loading : comparable -> Cache comparable value -> Cache comparable value
loading key =
    insertInternal key Loading



-- NICHE


fromResult : comparable -> Result Http.Error value -> Cache comparable value -> Cache comparable value
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


getDict : Cache comparable value -> Dict comparable (WebData value)
getDict (Cache dict) =
    dict


insertInternal : comparable -> WebData value -> Cache comparable value -> Cache comparable value
insertInternal key webData cache =
    cache
        |> getDict
        |> Dict.insert key webData
        |> Cache
