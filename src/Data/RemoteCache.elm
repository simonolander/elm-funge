module Data.RemoteCache exposing
    ( RemoteCache
    , empty
    , withActualError
    , withActualLoading
    , withActualResult
    , withActualValue
    , withExpectedValue
    , withLocalValue
    )

import Data.Cache as Cache exposing (Cache)
import Data.GetError exposing (GetError)
import Dict exposing (Dict)


type alias RemoteCache comparable value =
    { local : Dict comparable value
    , expected : Dict comparable value
    , actual : Cache comparable GetError value
    }


empty : RemoteCache comparable value
empty =
    { local = Dict.empty
    , expected = Dict.empty
    , actual = Cache.empty
    }



-- LOCAL


withLocalValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withLocalValue key value cache =
    { cache | local = Dict.insert key value cache.local }



-- EXPECTED


withExpectedValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withExpectedValue key value cache =
    { cache | expected = Dict.insert key value cache.expected }



-- ACTUAL


withActualValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withActualValue key value cache =
    { cache | actual = Cache.withValue key value cache.actual }


withActualLoading : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withActualLoading key cache =
    { cache | actual = Cache.loading key cache.actual }


withActualError : comparable -> GetError -> RemoteCache comparable value -> RemoteCache comparable value
withActualError key error cache =
    { cache | actual = Cache.withError key error cache.actual }


withActualResult : comparable -> Result GetError value -> RemoteCache comparable value -> RemoteCache comparable value
withActualResult key result cache =
    { cache | actual = Cache.withResult key result cache.actual }



-- WORKING


withWorkingValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withWorkingValue key value cache =
    { cache | actual = Cache.withValue key value cache.actual }


withWorkingLoading : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withWorkingLoading key cache =
    { cache | actual = Cache.loading key cache.actual }


withWorkingError : comparable -> GetError -> RemoteCache comparable value -> RemoteCache comparable value
withWorkingError key error cache =
    { cache | actual = Cache.withError key error cache.actual }
