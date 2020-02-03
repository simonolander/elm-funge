module Service.RemoteRequestDict exposing
    ( RemoteRequestDict
    , get
    , insertResult
    , loading
    , missingAccessToken
    )

import Basics.Extra exposing (flip)
import Data.GetError exposing (GetError(..))
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..), fromResult)


type alias RemoteRequestDict id =
    Dict id (RemoteData GetError ())


get : comparableId -> RemoteRequestDict comparableId -> RemoteData GetError ()
get id dict =
    Dict.get id dict
        |> Maybe.withDefault NotAsked


loading : comparableId -> Updater (RemoteRequestDict comparableId)
loading id dict =
    Dict.insert id Loading dict


missingAccessToken : comparableId -> Updater (RemoteRequestDict comparableId)
missingAccessToken id dict =
    Dict.insert id (Failure (InvalidAccessToken "Session expired")) dict


insertResult : comparableId -> Result GetError a -> Updater (RemoteRequestDict comparableId)
insertResult id result dict =
    Result.map (always ()) result
        |> fromResult
        |> flip (Dict.insert id) dict
