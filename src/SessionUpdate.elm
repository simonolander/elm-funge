module SessionUpdate exposing (SessionMsg(..), update)

import Basics.Extra exposing (flip)
import Data.Cache as Cache
import Data.Campaign as Campaign
import Data.CampaignId exposing (CampaignId)
import Data.DetailedHttpError as DetailedHttpError exposing (DetailedHttpError)
import Data.Draft as Draft exposing (Draft)
import Data.DraftBook as DraftBook
import Data.DraftId exposing (DraftId)
import Data.HighScore exposing (HighScore)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache
import Data.RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.SolutionBook as SolutionBook
import Data.SolutionId exposing (SolutionId)
import Extra.Cmd exposing (noCmd, withCmd, withExtraCmd)
import Extra.Result
import Ports.Console
import RemoteData exposing (RemoteData(..))
import Set


type SessionMsg
    = GotLoadHighScoreResponse (RequestResult LevelId DetailedHttpError HighScore)
    | GotLoadLevelsByCampaignIdResponse (RequestResult CampaignId DetailedHttpError (List Level))
    | GotLoadSolutionsByLevelIdResponse (RequestResult LevelId DetailedHttpError (List Solution))
    | GotLoadSolutionsBySolutionIdResponse (RequestResult SolutionId DetailedHttpError Solution)
    | GotLoadDraftByDraftIdResponse (RequestResult DraftId DetailedHttpError Draft)
    | GotLoadDraftByLevelIdResponse (RequestResult LevelId DetailedHttpError (List Draft))
    | GotLoadLevelResponse (RequestResult LevelId DetailedHttpError Level)
    | GotSaveDraftResponse (RequestResult Draft DetailedHttpError ())


update : SessionMsg -> Session -> ( Session, Cmd msg )
update msg session =
    case msg of
        GotLoadHighScoreResponse { request, result } ->
            session.highScores
                |> Cache.withResult request result
                |> flip Session.withHighScoreCache session
                |> withCmd
                    (Extra.Result.getError result
                        |> Maybe.map DetailedHttpError.consoleError
                        |> Maybe.withDefault Cmd.none
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

                Err error ->
                    session.campaigns
                        |> Cache.loading request
                        |> flip Session.withCampaignCache session
                        |> withCmd (Campaign.loadFromLocalStorage request)
                        |> withExtraCmd (DetailedHttpError.consoleError error)

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
                    session.solutionBooks
                        |> Cache.loading request
                        |> flip Session.withSolutionBookCache session
                        |> withCmd (SolutionBook.loadFromLocalStorage request)
                        |> withExtraCmd (DetailedHttpError.consoleError error)

        GotLoadLevelResponse { request, result } ->
            case result of
                Ok level ->
                    session.levels
                        |> Cache.withValue level.id level
                        |> flip Session.withLevelCache session
                        |> noCmd

                Err error ->
                    session.levels
                        |> Cache.loading request
                        |> flip Session.withLevelCache session
                        |> withCmd (Level.loadFromLocalStorage request)
                        |> withExtraCmd (DetailedHttpError.consoleError error)

        GotLoadSolutionsBySolutionIdResponse { request, result } ->
            case result of
                Ok solution ->
                    session.solutions
                        |> Cache.withValue solution.id solution
                        |> flip Session.withSolutionCache session
                        |> noCmd

                Err error ->
                    session.solutions
                        |> Cache.loading request
                        |> flip Session.withSolutionCache session
                        |> withCmd (Solution.loadFromLocalStorage request)
                        |> withExtraCmd (DetailedHttpError.consoleError error)

        GotLoadDraftByDraftIdResponse { request, result } ->
            let
                sessionWithActualDraft =
                    session.drafts
                        |> RemoteCache.withActualResult request result
                        |> flip Session.withDraftCache session
            in
            case result of
                Ok actualDraft ->
                    case Cache.get request sessionWithActualDraft.drafts.local of
                        Success localDraft ->
                            case Cache.get request sessionWithActualDraft.drafts.expected of
                                Success expectedDraft ->
                                    if Draft.eq localDraft actualDraft then
                                        if Draft.eq localDraft expectedDraft then
                                            noCmd sessionWithActualDraft

                                        else
                                            sessionWithActualDraft.drafts
                                                |> RemoteCache.withExpectedValue request actualDraft
                                                |> flip Session.withDraftCache sessionWithActualDraft
                                                |> withCmd (Draft.saveRemoteToLocalStorage actualDraft)

                                    else if Draft.eq localDraft expectedDraft then
                                        sessionWithActualDraft.drafts
                                            |> RemoteCache.withLocalValue request actualDraft
                                            |> RemoteCache.withExpectedValue request actualDraft
                                            |> flip Session.withDraftCache sessionWithActualDraft
                                            |> withCmd (Draft.saveRemoteToLocalStorage actualDraft)
                                            |> withExtraCmd (Draft.saveToLocalStorage actualDraft)

                                    else
                                        sessionWithActualDraft
                                            |> withCmd
                                                (Ports.Console.errorString
                                                    ("5107844dd836    Conflict in draft " ++ actualDraft.id)
                                                )

                                _ ->
                                    sessionWithActualDraft
                                        |> withCmd
                                            (Ports.Console.errorString
                                                ("c797bf8b5d8c    Conflict in draft " ++ actualDraft.id)
                                            )

                        _ ->
                            sessionWithActualDraft.drafts
                                |> RemoteCache.withLocalValue request actualDraft
                                |> RemoteCache.withExpectedValue request actualDraft
                                |> flip Session.withDraftCache sessionWithActualDraft
                                |> withCmd (Draft.saveRemoteToLocalStorage actualDraft)
                                |> withExtraCmd (Draft.saveToLocalStorage actualDraft)

                Err error ->
                    sessionWithActualDraft
                        |> withCmd (DetailedHttpError.consoleError error)

        GotLoadDraftByLevelIdResponse { request, result } ->
            case result of
                Ok drafts ->
                    let
                        draftBook =
                            session.draftBooks
                                |> Cache.get request
                                |> Cache.withDefault (DraftBook.empty request)
                                |> DraftBook.withDraftIds (List.map .id drafts)

                        draftBookCache =
                            Cache.withValue request draftBook session.draftBooks

                        draftCache =
                            List.foldl (\draft cache -> Cache.withValue draft.id draft cache) session.drafts

                        saveDraftsLocallyCmd =
                            List.map Draft.saveRemoteToLocalStorage drafts
                    in
                    session.draftBooks
                        |> Cache.withValue request draftBook
                        |> Session.withDraftBookCache

                Err error ->
                    Debug.todo ""

        GotSaveDraftResponse { request, result } ->
            case result of
                Ok () ->
                    session.drafts
                        |> RemoteCache.withActualValue request.id request
                        |> RemoteCache.withExpectedValue request.id request
                        |> flip Session.withDraftCache session
                        |> withCmd (Draft.saveRemoteToLocalStorage request)

                Err error ->
                    session.drafts
                        |> RemoteCache.withActualResult request.id (Err error)
                        |> flip Session.withDraftCache session
                        |> withCmd (DetailedHttpError.consoleError error)
