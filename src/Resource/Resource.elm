module Resource.Resource exposing (Resource, empty, updateActual, updateExpected, updateLocal, updateSaving)

import Data.GetError exposing (GetError)
import Data.SaveError exposing (SaveError)
import Data.SaveRequest exposing (SaveRequest)
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData)


type alias Resource id res a =
    { a
        | local : Dict id (Maybe res)
        , expected : Dict id (Maybe res)
        , actual : Dict id (RemoteData GetError (Maybe res))
        , saving : Dict id (SaveRequest SaveError (Maybe res))
    }


empty : Resource id res a
empty =
    { local = Dict.empty
    , expected = Dict.empty
    , actual = Dict.empty
    , saving = Dict.empty
    }


updateLocal : Updater (Dict id (Maybe res)) -> Updater (Resource id res a)
updateLocal update resource =
    { resource | local = update resource.local }


updateExpected : Updater (Dict id (Maybe res)) -> Updater (Resource id res a)
updateExpected update resource =
    { resource | expected = update resource.expected }


updateActual : Updater (Dict id (RemoteData GetError (Maybe res))) -> Updater (Resource id res a)
updateActual update resource =
    { resource | actual = update resource.actual }


updateSaving : Updater (Dict id (SaveRequest SaveError (Maybe res))) -> Updater (Resource id res a)
updateSaving update resource =
    { resource | saving = update resource.saving }
