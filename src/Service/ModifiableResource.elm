module Resource.ModifiableResource exposing
    ( ModifiableRemoteResource
    , getAllIds
    , loadedTriplets
    , updateActual
    , updateExpected
    , updateLocal
    , updateSaving
    )

import Data.GetError exposing (GetError)
import Data.SaveError exposing (SaveError)
import Data.SaveRequest exposing (SaveRequest)
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import List.Extra
import RemoteData exposing (RemoteData)
import Service.RemoteResource exposing (RemoteResource)


type alias ModifiableRemoteResource id res a =
    RemoteResource id
        res
        { a
            | local : Dict id (Maybe res)
            , expected : Dict id (Maybe res)
            , saving : Dict id (SaveRequest SaveError (Maybe res))
        }


updateLocal : Updater (Dict id (Maybe res)) -> Updater (ModifiableRemoteResource id res a)
updateLocal update resource =
    { resource | local = update resource.local }


updateExpected : Updater (Dict id (Maybe res)) -> Updater (ModifiableRemoteResource id res a)
updateExpected update resource =
    { resource | expected = update resource.expected }


updateActual : Updater (Dict id (RemoteData GetError (Maybe res))) -> Updater (ModifiableRemoteResource id res a)
updateActual update resource =
    { resource | actual = update resource.actual }


updateSaving : Updater (Dict id (SaveRequest SaveError (Maybe res))) -> Updater (ModifiableRemoteResource id res a)
updateSaving update resource =
    { resource | saving = update resource.saving }


getAllIds : ModifiableRemoteResource comparableId res a -> List comparableId
getAllIds resource =
    [ Dict.keys resource.local, Dict.keys resource.expected, Dict.keys resource.actual ]
        |> List.concat
        |> List.Extra.unique


loadedTriplets : ModifiableRemoteResource comparableId res a -> List { id : comparableId, maybeLocal : Maybe (Maybe res), maybeExpected : Maybe (Maybe res), maybeActual : Maybe res }
loadedTriplets resource =
    getAllIds resource
        |> List.filterMap
            (\id ->
                case
                    Dict.get id resource.actual
                        |> Maybe.andThen RemoteData.toMaybe
                of
                    Just maybeActual ->
                        Just
                            { id = id
                            , maybeLocal = Dict.get id resource.local
                            , maybeExpected = Dict.get id resource.expected
                            , maybeActual = maybeActual
                            }

                    Nothing ->
                        Nothing
            )
