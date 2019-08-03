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
    = GotLoadDraftByDraftIdResponse (RequestResult DraftId DetailedHttpError Draft)
    | GotLoadDraftsByLevelIdResponse (RequestResult LevelId DetailedHttpError (List Draft))
    | GotLoadHighScoreResponse (RequestResult LevelId DetailedHttpError HighScore)
    | GotLoadLevelResponse (RequestResult LevelId DetailedHttpError Level)
    | GotLoadLevelsByCampaignIdResponse (RequestResult CampaignId DetailedHttpError (List Level))
    | GotLoadSolutionsByLevelIdResponse (RequestResult LevelId DetailedHttpError (List Solution))
    | GotLoadSolutionsBySolutionIdResponse (RequestResult SolutionId DetailedHttpError Solution)
    | GotSaveDraftResponse (RequestResult Draft DetailedHttpError ())
    | GotSaveSolutionResponse (RequestResult Solution DetailedHttpError ())


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
                        |> withCmd (Level.saveToLocalStorage level)

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
                    gotActualDraft actualDraft sessionWithActualDraft

                Err error ->
                    sessionWithActualDraft
                        |> withCmd (DetailedHttpError.consoleError error)

        GotLoadDraftsByLevelIdResponse { request, result } ->
            case result of
                Ok drafts ->
                    let
                        draftBook =
                            session.draftBooks
                                |> Cache.get request
                                |> RemoteData.withDefault (DraftBook.empty request)
                                |> DraftBook.withDraftIds (Set.fromList (List.map .id drafts))

                        draftBookCache =
                            Cache.withValue request draftBook session.draftBooks

                        sessionWithDraftBookCache =
                            Session.withDraftBookCache draftBookCache session
                    in
                    Extra.Cmd.fold (List.map gotActualDraft drafts) sessionWithDraftBookCache

                Err error ->
                    session.draftBooks
                        |> Cache.loading request
                        |> flip Session.withDraftBookCache session
                        |> withCmd (DraftBook.loadFromLocalStorage request)
                        |> withExtraCmd (DetailedHttpError.consoleError error)

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

        GotSaveSolutionResponse { request, result } ->
            let
                solution =
                    { request | published = True }
            in
            case result of
                Ok () ->
                    session.solutions
                        |> Cache.withValue solution.id solution
                        |> flip Session.withSolutionCache session
                        |> withCmd (Solution.saveToLocalStorage solution)

                Err error ->
                    session
                        |> withCmd (DetailedHttpError.consoleError error)


gotActualDraft : Draft -> Session -> ( Session, Cmd msg )
gotActualDraft actualDraft session =
    case Cache.get actualDraft.id session.drafts.local of
        Success localDraft ->
            case Cache.get actualDraft.id session.drafts.expected of
                Success expectedDraft ->
                    if Draft.eq localDraft actualDraft then
                        if Draft.eq localDraft expectedDraft then
                            noCmd session

                        else
                            session.drafts
                                |> RemoteCache.withExpectedValue actualDraft.id actualDraft
                                |> flip Session.withDraftCache session
                                |> withCmd (Draft.saveRemoteToLocalStorage actualDraft)

                    else if Draft.eq localDraft expectedDraft then
                        session.drafts
                            |> RemoteCache.withLocalValue actualDraft.id actualDraft
                            |> RemoteCache.withExpectedValue actualDraft.id actualDraft
                            |> flip Session.withDraftCache session
                            |> withCmd (Draft.saveRemoteToLocalStorage actualDraft)
                            |> withExtraCmd (Draft.saveToLocalStorage actualDraft)

                    else
                        session
                            |> withCmd
                                (Ports.Console.errorString
                                    ("5107844dd836    Conflict in draft " ++ actualDraft.id)
                                )

                _ ->
                    session
                        |> withCmd
                            (Ports.Console.errorString
                                ("c797bf8b5d8c    Conflict in draft " ++ actualDraft.id)
                            )

        _ ->
            session.drafts
                |> RemoteCache.withLocalValue actualDraft.id actualDraft
                |> RemoteCache.withExpectedValue actualDraft.id actualDraft
                |> flip Session.withDraftCache session
                |> withCmd (Draft.saveRemoteToLocalStorage actualDraft)
                |> withExtraCmd (Draft.saveToLocalStorage actualDraft)
