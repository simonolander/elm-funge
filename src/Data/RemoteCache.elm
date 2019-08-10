module Data.RemoteCache exposing
    ( RemoteCache
    , empty
    , withActualError
    , withActualLoading
    , withActualResult
    , withActualValue
    , withExpectedError
    , withExpectedLoading
    , withExpectedResult
    , withExpectedValue
    , withLocalError
    , withLocalLoading
    , withLocalResult
    , withLocalValue
    , withoutActual
    , withoutExpected
    , withoutLocal
    )

import Data.Cache as Cache exposing (Cache)
import Data.GetError exposing (GetError)
import Json.Decode as Decode


type alias RemoteCache comparable value =
    { local : Cache comparable Decode.Error value
    , expected : Cache comparable Decode.Error value
    , actual : Cache comparable GetError value
    }


empty : RemoteCache comparable value
empty =
    { local = Cache.empty
    , expected = Cache.empty
    , actual = Cache.empty
    }



-- LOCAL


withLocalValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withLocalValue key value cache =
    { cache | local = Cache.withValue key value cache.local }


withLocalLoading : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withLocalLoading key cache =
    { cache | local = Cache.loading key cache.local }


withLocalError : comparable -> Decode.Error -> RemoteCache comparable value -> RemoteCache comparable value
withLocalError key error cache =
    { cache | local = Cache.withError key error cache.local }


withLocalResult : comparable -> Result Decode.Error value -> RemoteCache comparable value -> RemoteCache comparable value
withLocalResult key result cache =
    { cache | local = Cache.withResult key result cache.local }


withoutLocal : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withoutLocal key cache =
    { cache | local = Cache.remove key cache.local }



-- EXPECTED


withExpectedValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withExpectedValue key value cache =
    { cache | expected = Cache.withValue key value cache.expected }


withExpectedLoading : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withExpectedLoading key cache =
    { cache | expected = Cache.loading key cache.expected }


withExpectedError : comparable -> Decode.Error -> RemoteCache comparable value -> RemoteCache comparable value
withExpectedError key error cache =
    { cache | expected = Cache.withError key error cache.expected }


withExpectedResult : comparable -> Result Decode.Error value -> RemoteCache comparable value -> RemoteCache comparable value
withExpectedResult key result cache =
    { cache | expected = Cache.withResult key result cache.expected }


withoutExpected : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withoutExpected key cache =
    { cache | expected = Cache.remove key cache.expected }



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


withoutActual : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withoutActual key cache =
    { cache | actual = Cache.remove key cache.actual }
