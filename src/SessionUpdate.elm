module SessionUpdate exposing (SessionMsg(..), update)

import Basics.Extra exposing (flip)
import Data.Cache as Cache
import Data.Campaign as Campaign
import Data.CampaignId exposing (CampaignId)
import Data.DetailedHttpError as DetailedHttpError exposing (DetailedHttpError)
import Data.Draft exposing (Draft)
import Data.HighScore exposing (HighScore)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache
import Data.RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.SolutionBook as SolutionBook
import Extra.Cmd exposing (noCmd, withCmd, withExtraCmd)
import Set


type SessionMsg
    = GotLoadHighScoreResponse (RequestResult LevelId DetailedHttpError HighScore)
    | GotLoadLevelsByCampaignIdResponse (RequestResult CampaignId DetailedHttpError (List Level))
    | GotLoadSolutionsByLevelIdResponse (RequestResult LevelId DetailedHttpError (List Solution))
    | GotSaveDraftResponse (RequestResult Draft DetailedHttpError ())
    | GotLoadLevelResponse (RequestResult LevelId DetailedHttpError Level)


update : SessionMsg -> Session -> ( Session, Cmd msg )
update msg session =
    case msg of
        GotLoadHighScoreResponse requestResult ->
            ( Session.withHighScoreResult requestResult session
            , Cmd.none
            )

        GotLoadLevelsByCampaignIdResponse { request, result } ->
            case result of
                Ok levels ->
                    let
                        campaign =
                            { id = request
                            , levelIds = List.map .id levels
                            }

                        saveCampaignLocallyCmd =
                            Campaign.saveToLocalStorage campaign

                        saveLevelsLocallyCmd =
                            levels
                                |> List.map Level.saveToLocalStorage
                                |> Cmd.batch

                        cmd =
                            Cmd.batch
                                [ saveCampaignLocallyCmd
                                , saveLevelsLocallyCmd
                                ]
                    in
                    ( session
                        |> Session.withCampaign campaign
                        |> Session.withLevels levels
                    , cmd
                    )

                -- TODO
                Err error ->
                    ( session
                    , Cmd.batch
                        [ DetailedHttpError.consoleError error
                        , Campaign.loadFromLocalStorage request
                        ]
                    )

        GotLoadSolutionsByLevelIdResponse { request, result } ->
            case result of
                Ok solutions ->
                    let
                        solutionBook =
                            { levelId = request
                            , solutionIds =
                                solutions
                                    |> List.map .id
                                    |> Set.fromList
                            }

                        cmd =
                            solutions
                                |> List.map Solution.saveToLocalStorage
                                |> Cmd.batch
                    in
                    ( session
                        |> Session.withSolutionBook solutionBook
                        |> Session.withSolutions solutions
                    , cmd
                    )

                Err error ->
                    session
                        |> withCmd (SolutionBook.loadFromLocalStorage request)
                        |> withExtraCmd (DetailedHttpError.consoleError error)

        GotSaveDraftResponse { request, result } ->
            case result of
                Ok () ->
                    session.drafts
                        |> RemoteCache.withActualValue request.id request
                        |> RemoteCache.withExpectedValue request.id request
                        |> flip Session.withDraftCache session
                        |> noCmd

                Err error ->
                    session
                        |> withCmd (DetailedHttpError.consoleError error)

        GotLoadLevelResponse { request, result } ->
            case result of
                Ok level ->
                    session.levels
                        |> Cache.insert level.id level
                        |> flip Session.withLevelCache session
                        |> noCmd

                Err error ->
                    session
                        |> withCmd (Level.loadFromLocalStorage request)
                        |> withExtraCmd (DetailedHttpError.consoleError error)
