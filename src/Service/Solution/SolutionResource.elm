module Service.Solution.SolutionResource exposing
    ( SolutionResource
    , empty
    , updateSolutionsByLevelIdRequests
    )

import Data.LevelId exposing (LevelId)
import Data.Solution exposing (Solution)
import Data.SolutionId exposing (SolutionId)
import Data.Updater exposing (Updater)
import Dict exposing (Dict)
import Service.ModifiableRemoteResource exposing (ModifiableRemoteResource)
import Service.RemoteRequestDict exposing (RemoteRequestDict)
import Service.RemoteResource exposing (RemoteResource)


type alias SolutionResource =
    ModifiableRemoteResource SolutionId Solution { solutionsByLevelIdRequests : RemoteRequestDict LevelId }


empty : SolutionResource
empty =
    { actual = Dict.empty
    , local = Dict.empty
    , expected = Dict.empty
    , saving = Dict.empty
    , solutionsByLevelIdRequests = Dict.empty
    }


updateSolutionsByLevelIdRequests : Updater (RemoteRequestDict LevelId) -> Updater SolutionResource
updateSolutionsByLevelIdRequests updater resource =
    { resource | solutionsByLevelIdRequests = updater resource.solutionsByLevelIdRequests }
