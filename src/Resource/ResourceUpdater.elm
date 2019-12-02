module Resource.ResourceUpdater exposing (loadResourceById)

import Api.GCP as GCP
import Basics.Extra exposing (flip)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withCmd)
import Data.GetError as GetError exposing (GetError)
import Data.Session exposing (Session)
import Data.Updater exposing (Updater)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Dict
import Json.Decode exposing (Decoder)
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Resource.MIsc exposing (resolveConflict)
import Resource.Resource as Resource exposing (updateActual)
import Update.General exposing (gotGetError)
import Update.SessionMsg exposing (SessionMsg)


type alias Interface id res a =
    { getLocal : id -> Session -> Maybe (Maybe res)
    , getActual : id -> Session -> Maybe (RemoteData GetError res)
    , updateSession : Updater (Resource.Resource id res a) -> Updater Session
    , path : List String
    , idParameterName : String
    , decoder : Decoder res
    , message : id -> Result GetError.GetError (Maybe res) -> SessionMsg
    , idToString : id -> String
    }


loadResourceById : Interface comparableId res a -> comparableId -> CmdUpdater Session SessionMsg
loadResourceById interface id session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                interface.getActual id session
                    |> Maybe.withDefault NotAsked
                    |> RemoteData.isNotAsked
            then
                Dict.insert id Loading
                    |> updateActual
                    |> flip interface.updateSession session
                    |> withCmd
                        (GCP.get
                            |> GCP.withPath interface.path
                            |> GCP.withAccessToken accessToken
                            |> GCP.withStringQueryParameter interface.idParameterName (interface.idToString id)
                            |> GCP.request (GetError.expectMaybe interface.decoder (interface.message id))
                        )

            else
                ( session, Cmd.none )

        Nothing ->
            Dict.insert id NotAsked
                |> Resource.updateActual
                |> flip interface.updateSession session
                |> CmdUpdater.id


getResourceById : Interface comparableId res a -> comparableId -> Session -> RemoteData GetError (Maybe res)
getResourceById interface id session =
    case interface.getActual id session of
        Nothing ->
            NotAsked

        Just Loading ->
            Loading

        Just (Failure error) ->
            Failure error

        _ ->
            interface.getLocal id session
                |> Maybe.Extra.join
                |> Success


gotLoadResourceByIdResponse : Interface comparableId res a -> comparableId -> Result GetError (Maybe res) -> CmdUpdater Session SessionMsg
gotLoadResourceByIdResponse interface id result session =
    let
        session =
            RemoteData.fromResult result
                |> Dict.insert id
                |> updateActual
                |> flip interface.updateSession session
    in
    case result of
        Ok maybeActual ->
            resolveConflict id maybeActual session

        Err error ->
            gotGetError error session
