module Data.RemoteCache exposing
    ( RemoteCache
    , empty
    , withLocal
    , withNewRemote
    , withOldRemote
    )

import Data.Cache as Cache exposing (Cache)


type alias RemoteCache comparable value =
    { local : Cache comparable value
    , oldRemote : Cache comparable value
    , newRemote : Cache comparable value
    }


empty : RemoteCache comparable value
empty =
    { local = Cache.empty
    , oldRemote = Cache.empty
    , newRemote = Cache.empty
    }


withLocal : Cache comparable value -> RemoteCache comparable value -> RemoteCache comparable value
withLocal cache remoteCache =
    { remoteCache
        | local = cache
    }


withOldRemote : Cache comparable value -> RemoteCache comparable value -> RemoteCache comparable value
withOldRemote cache remoteCache =
    { remoteCache
        | oldRemote = cache
    }


withNewRemote : Cache comparable value -> RemoteCache comparable value -> RemoteCache comparable value
withNewRemote cache remoteCache =
    { remoteCache
        | newRemote = cache
    }
