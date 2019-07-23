module Data.RemoteCache exposing (RemoteCache, empty, withActualLoading, withActualResult, withActualValue, withExpectedLoading, withExpectedResult, withExpectedValue, withLocalLoading, withLocalResult, withLocalValue)

import Data.Cache as Cache exposing (Cache)
import Data.DetailedHttpError exposing (DetailedHttpError)


type alias RemoteCache comparable value =
    { local : Cache comparable value
    , expected : Cache comparable value
    , actual : Cache comparable value
    }


empty : RemoteCache comparable value
empty =
    { local = Cache.empty
    , expected = Cache.empty
    , actual = Cache.empty
    }


withLocalValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withLocalValue key value cache =
    { cache | local = Cache.insert key value cache.local }


withLocalLoading : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withLocalLoading key cache =
    { cache | local = Cache.loading key cache.local }


withLocalResult : comparable -> Result DetailedHttpError value -> RemoteCache comparable value -> RemoteCache comparable value
withLocalResult key result cache =
    { cache | local = Cache.withResult key result cache.local }


withExpectedValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withExpectedValue key value cache =
    { cache | expected = Cache.insert key value cache.expected }


withExpectedLoading : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withExpectedLoading key cache =
    { cache | expected = Cache.loading key cache.expected }


withExpectedResult : comparable -> Result DetailedHttpError value -> RemoteCache comparable value -> RemoteCache comparable value
withExpectedResult key result cache =
    { cache | expected = Cache.withResult key result cache.expected }


withActualValue : comparable -> value -> RemoteCache comparable value -> RemoteCache comparable value
withActualValue key value cache =
    { cache | actual = Cache.insert key value cache.actual }


withActualLoading : comparable -> RemoteCache comparable value -> RemoteCache comparable value
withActualLoading key cache =
    { cache | actual = Cache.loading key cache.actual }


withActualResult : comparable -> Result DetailedHttpError value -> RemoteCache comparable value -> RemoteCache comparable value
withActualResult key result cache =
    { cache | actual = Cache.withResult key result cache.actual }
