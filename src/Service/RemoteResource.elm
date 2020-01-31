module Service.RemoteResource exposing (RemoteResource)

import Resource.RemoteDataDict exposing (RemoteDataDict)


type alias RemoteResource id res a =
    { a
        | actual : RemoteDataDict id res
    }
