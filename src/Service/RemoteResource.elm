module Service.RemoteResource exposing
    ( RemoteResource
    , getResourceById
    , updateActual
    )

import Data.GetError exposing (GetError)
import Data.Updater exposing (Updater)
import RemoteData exposing (RemoteData)
import Service.RemoteDataDict exposing (RemoteDataDict, get)


type alias RemoteResource id res a =
    { a
        | actual : RemoteDataDict id res
    }


getResourceById : comparable -> RemoteResource comparable res a -> RemoteData GetError (Maybe res)
getResourceById id remoteResource =
    get id remoteResource.actual


updateActual : Updater (RemoteDataDict id res) -> Updater (RemoteResource id res a)
updateActual updater remoteResource =
    { remoteResource | actual = updater remoteResource.actual }
