module Service.Solution.SolutionService exposing
    ( createFromLocalStorageEntries
    , getSolutionBySolutionId
    , getSolutionsByLevelId
    , gotLoadSolutionBySolutionIdResponse
    , gotLoadSolutionsByLevelIdResponse
    , loadSolutionBySolutionId
    , loadSolutionsByLevelId
    , loadSolutionsBySolutionIds
    )

import Api.GCP as GCP
import Basics.Extra exposing (flip, uncurry)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withCmd)
import Data.GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.Session exposing (Session)
import Data.Solution as Solution exposing (Solution, decoder)
import Data.SolutionId exposing (SolutionId)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Dict
import Extra.Tuple exposing (fanout)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Service.InterfaceHelper exposing (createRemoteResourceInterface)
import Service.LoadResourceService exposing (LoadResourceInterface, gotGetError, gotLoadResourceByIdResponse, loadPrivateResourceById)
import Service.LocalStorageService exposing (getResourcesFromLocalStorageEntries)
import Service.RemoteDataDict as RemoteDataDict
import Service.RemoteRequestDict as RemoteRequestDict
import Service.RemoteResource as RemoteResource
import Service.ResourceType as ResourceType exposing (toIdParameterName, toPath)
import Service.Solution.SolutionResource exposing (SolutionResource, empty, updateSolutionsByLevelIdRequests)
import Update.SessionMsg exposing (SessionMsg(..))


interface =
    createRemoteResourceInterface
        { getRemoteResource = .solutions
        , setRemoteResource = \r s -> { s | solutions = r }
        , encode = Solution.encode
        , decoder = Solution.decoder
        , resourceType = ResourceType.Solution
        , toString = identity
        , toKey = identity
        , fromKey = identity
        , fromString = identity
        , responseMsg = GotLoadSolutionBySolutionIdResponse
        }


createFromLocalStorageEntries : List ( String, Encode.Value ) -> ( SolutionResource, List ( String, Decode.Error ) )
createFromLocalStorageEntries localStorageEntries =
    let
        { current, expected, errors } =
            getResourcesFromLocalStorageEntries interface localStorageEntries
    in
    ( { empty
        | actual = RemoteDataDict.fromList current
      }
    , errors
    )



-- LOAD BY ID


getSolutionBySolutionId : SolutionId -> Session -> RemoteData GetError (Maybe Solution)
getSolutionBySolutionId solutionId session =
    interface.getRemoteResource session
        |> RemoteResource.getResourceById solutionId


loadSolutionsBySolutionIds : List SolutionId -> CmdUpdater Session SessionMsg
loadSolutionsBySolutionIds solutionIds session =
    List.map loadSolutionBySolutionId solutionIds
        |> flip CmdUpdater.batch session


loadSolutionBySolutionId : SolutionId -> CmdUpdater Session SessionMsg
loadSolutionBySolutionId =
    loadPrivateResourceById interface


gotLoadSolutionBySolutionIdResponse : SolutionId -> Result GetError (Maybe Solution) -> CmdUpdater Session SessionMsg
gotLoadSolutionBySolutionIdResponse =
    gotLoadResourceByIdResponse interface



-- LOAD BY LEVEL ID


getSolutionsByLevelId : LevelId -> Session -> RemoteData GetError (List Solution)
getSolutionsByLevelId levelId session =
    case
        interface.getRemoteResource session
            |> .solutionsByLevelIdRequests
            |> RemoteRequestDict.get levelId
    of
        NotAsked ->
            NotAsked

        Loading ->
            Loading

        Failure e ->
            -- TODO Maybe return (List Solution, Maybe GetError)?
            let
                availableBlueprints =
                    interface.getRemoteResource session
                        |> .actual
                        |> Dict.values
                        |> List.filterMap RemoteData.toMaybe
                        |> Maybe.Extra.values
            in
            if List.isEmpty availableBlueprints then
                Failure e

            else
                Success availableBlueprints

        Success () ->
            interface.getRemoteResource session
                |> .actual
                |> Dict.values
                |> List.filterMap RemoteData.toMaybe
                |> Maybe.Extra.values
                |> Success


loadSolutionsByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionsByLevelId levelId session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                interface.getRemoteResource session
                    |> .solutionsByLevelIdRequests
                    |> Dict.get levelId
                    |> Maybe.withDefault NotAsked
                    |> RemoteData.isNotAsked
            then
                Dict.insert levelId Loading
                    |> updateSolutionsByLevelIdRequests
                    |> flip interface.updateRemoteResource session
                    |> withCmd
                        (GCP.get
                            |> GCP.withPath (toPath interface.resourceType)
                            |> GCP.withAccessToken accessToken
                            |> GCP.withStringQueryParameter (toIdParameterName ResourceType.Level) levelId
                            |> GCP.request (Data.GetError.expect (Decode.list decoder) (GotLoadSolutionsByLevelIdResponse levelId))
                        )

            else
                ( session, Cmd.none )

        Nothing ->
            ( session, Cmd.none )


gotLoadSolutionsByLevelIdResponse : LevelId -> Result GetError (List Solution) -> Session -> ( Session, Cmd SessionMsg )
gotLoadSolutionsByLevelIdResponse levelId result oldSession =
    let
        session =
            RemoteData.fromResult result
                |> RemoteData.map (always ())
                |> Dict.insert levelId
                |> updateSolutionsByLevelIdRequests
                |> flip interface.updateRemoteResource oldSession
    in
    case result of
        Ok solutions ->
            List.map (fanout .id Just) solutions
                |> List.map (uncurry interface.mergeResource)
                |> flip CmdUpdater.batch session

        Err error ->
            gotGetError error session
