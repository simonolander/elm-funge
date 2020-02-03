module Service.RemoteDataDict exposing
    ( RemoteDataDict
    , fromList
    , get
    , insertResult
    , insertValue
    , loading
    , missingAccessToken
    )

import Data.GetError exposing (GetError(..))
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import RemoteData exposing (RemoteData(..), fromResult)


type alias RemoteDataDict id res =
    Dict id (RemoteData GetError (Maybe res))


get : comparableId -> RemoteDataDict comparableId res -> RemoteData GetError (Maybe res)
get id dict =
    Dict.get id dict
        |> Maybe.withDefault NotAsked


loading : comparableId -> Updater (RemoteDataDict comparableId res)
loading id dict =
    Dict.insert id Loading dict


missingAccessToken : comparableId -> Updater (RemoteDataDict comparableId res)
missingAccessToken id dict =
    Dict.insert id (Failure (InvalidAccessToken "Session expired")) dict


insertResult : comparableId -> Result GetError (Maybe res) -> Updater (RemoteDataDict comparableId res)
insertResult id result dict =
    Dict.insert id (fromResult result) dict


insertValue : comparableId -> Maybe res -> Updater (RemoteDataDict comparableId res)
insertValue id maybeResource dict =
    Dict.insert id (Success maybeResource) dict


fromList : List ( comparable, Maybe res ) -> RemoteDataDict comparable res
fromList list =
    List.map (Tuple.mapSecond Success) list
        |> Dict.fromList
