module SessionUpdate exposing (SessionMsg(..), update)

import Basics.Extra exposing (flip)
import Data.Cache as Cache
import Data.Campaign as Campaign
import Data.CampaignId exposing (CampaignId)
import Data.Draft as Draft exposing (Draft)
import Data.DraftBook as DraftBook
import Data.DraftId exposing (DraftId)
import Data.GetError as GetError exposing (GetError)
import Data.HighScore exposing (HighScore)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache
import Data.SaveError as SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.SolutionBook as SolutionBook
import Data.SolutionId exposing (SolutionId)
import Extra.Cmd exposing (withCmd, withExtraCmd)
import Extra.Result
import Maybe.Extra
import Ports.Console
import RemoteData exposing (RemoteData(..))
import Set


type SessionMsg
    = GotDeleteDraftResponse DraftId (Maybe SaveError)
    | GotLoadDraftByDraftIdResponse DraftId (Result GetError (Maybe Draft))
    | GotLoadDraftsByLevelIdResponse LevelId (Result GetError (List Draft))
    | GotLoadHighScoreResponse LevelId (Result GetError HighScore)
    | GotLoadLevelByLevelIdResponse LevelId (Result GetError Level)
    | GotLoadLevelsByCampaignIdResponse CampaignId (Result GetError (List Level))
    | GotLoadSolutionsByLevelIdResponse LevelId (Result GetError (List Solution))
    | GotLoadSolutionsBySolutionIdResponse SolutionId (Result GetError (Maybe Solution))
    | GotSaveDraftResponse Draft (Maybe SaveError)
    | GotSaveSolutionResponse Solution (Maybe SaveError)


update : SessionMsg -> Session -> ( Session, Cmd msg )
update msg session =
    case msg of
        GotDeleteDraftResponse draftId result ->
            case result of
                Nothing ->
                    session.drafts
                        |> RemoteCache.withActualValue draftId Nothing
                        |> RemoteCache.withExpectedValue draftId Nothing
                        |> flip Session.withDraftCache session
                        |> withCmd (Draft.removeRemoteFromLocalStorage draftId)

                Just error ->
                    ( session, SaveError.consoleError error )

        GotLoadHighScoreResponse levelId result ->
            session.highScores
                |> Cache.withResult levelId result
                |> flip Session.withHighScoreCache session
                |> withCmd
                    (Extra.Result.getError result
                        |> Maybe.map GetError.consoleError
                        |> Maybe.withDefault Cmd.none
                    )

        GotLoadLevelsByCampaignIdResponse campaignId result ->
            case result of
                Ok levels ->
                    let
                        campaign =
                            { id = campaignId
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
                        |> Cache.loading campaignId
                        |> flip Session.withCampaignCache session
                        |> withCmd (Campaign.loadFromLocalStorage campaignId)
                        |> withExtraCmd (GetError.consoleError error)

        GotLoadSolutionsByLevelIdResponse request result ->
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

                        sessionWithSolutionBookCache =
                            session
                                |> Session.withSolutionBook solutionBook

                        cmd =
                            solutions
                                |> List.map Solution.saveToLocalStorage
                                |> Cmd.batch
                    in
                    Extra.Cmd.fold
                        (List.map (\solution -> gotActualSolution solution.id (Just solution)) solutions)
                        sessionWithSolutionBookCache
                        |> withExtraCmd cmd

                Err error ->
                    session.solutionBooks
                        |> Cache.loading request
                        |> flip Session.withSolutionBookCache session
                        |> withCmd (SolutionBook.loadFromLocalStorage request)
                        |> withExtraCmd (GetError.consoleError error)

        GotLoadLevelByLevelIdResponse levelId result ->
            case result of
                Ok level ->
                    session.levels
                        |> Cache.withValue level.id level
                        |> flip Session.withLevelCache session
                        |> withCmd (Level.saveToLocalStorage level)

                Err error ->
                    session.levels
                        |> Cache.loading levelId
                        |> flip Session.withLevelCache session
                        |> withCmd (Level.loadFromLocalStorage levelId)
                        |> withExtraCmd (GetError.consoleError error)

        GotLoadSolutionsBySolutionIdResponse solutionId result ->
            let
                sessionWithSolution =
                    session.solutions
                        |> RemoteCache.withActualResult solutionId result
                        |> flip Session.withSolutionCache session
            in
            case result of
                Ok solution ->
                    gotActualSolution solutionId solution sessionWithSolution

                Err error ->
                    sessionWithSolution.solutions
                        |> RemoteCache.withLocalLoading solutionId
                        |> flip Session.withSolutionCache sessionWithSolution
                        |> withCmd (Solution.loadFromLocalStorage solutionId)
                        |> withExtraCmd (GetError.consoleError error)

        GotLoadDraftByDraftIdResponse draftId result ->
            let
                sessionWithActualDraft =
                    session.drafts
                        |> RemoteCache.withActualResult draftId result
                        |> flip Session.withDraftCache session
            in
            case result of
                Ok actualDraft ->
                    gotActualDraft draftId actualDraft sessionWithActualDraft

                Err GetError.NetworkError ->
                    Session.withoutAccessToken sessionWithActualDraft
                        |> withCmd (Ports.Console.infoString "No network, going offline")

                Err error ->
                    sessionWithActualDraft
                        |> withCmd (GetError.consoleError error)

        GotLoadDraftsByLevelIdResponse request result ->
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
                    Extra.Cmd.fold (List.map (\draft -> gotActualDraft draft.id (Just draft)) drafts) sessionWithDraftBookCache

                Err error ->
                    session.draftBooks
                        |> Cache.loading request
                        |> flip Session.withDraftBookCache session
                        |> withCmd (DraftBook.loadFromLocalStorage request)
                        |> withExtraCmd (GetError.consoleError error)

        GotSaveDraftResponse draft result ->
            case result of
                Nothing ->
                    session.drafts
                        |> RemoteCache.withActualValue draft.id (Just draft)
                        |> RemoteCache.withExpectedValue draft.id (Just draft)
                        |> flip Session.withDraftCache session
                        |> withCmd (Draft.saveRemoteToLocalStorage draft)

                Just error ->
                    ( session, SaveError.consoleError error )

        GotSaveSolutionResponse solution result ->
            case result of
                Nothing ->
                    session.solutions
                        |> RemoteCache.withActualValue solution.id (Just solution)
                        |> RemoteCache.withExpectedValue solution.id (Just solution)
                        |> flip Session.withSolutionCache session
                        |> withCmd (Solution.saveToLocalStorage solution)

                Just error ->
                    ( session, SaveError.consoleError error )


gotActualDraft : DraftId -> Maybe Draft -> Session -> ( Session, Cmd msg )
gotActualDraft draftId maybeActualDraft session =
    let
        sessionWithActualDraft =
            session.drafts
                |> RemoteCache.withActualValue draftId maybeActualDraft
                |> flip Session.withDraftCache session

        overwrite draft =
            sessionWithActualDraft.drafts
                |> RemoteCache.withLocalValue draftId (Just draft)
                |> RemoteCache.withExpectedValue draftId (Just draft)
                |> flip Session.withDraftCache sessionWithActualDraft
                |> withCmd (Draft.saveRemoteToLocalStorage draft)
                |> withExtraCmd (Draft.saveToLocalStorage draft)
    in
    case maybeActualDraft of
        Just actualDraft ->
            case
                Cache.get draftId sessionWithActualDraft.drafts.local
                    |> RemoteData.toMaybe
                    |> Maybe.Extra.join
            of
                Nothing ->
                    overwrite actualDraft

                Just localDraft ->
                    if
                        Cache.get draftId sessionWithActualDraft.drafts.expected
                            |> RemoteData.toMaybe
                            |> Maybe.Extra.join
                            |> Maybe.map (Draft.eq localDraft)
                            |> Maybe.withDefault False
                    then
                        overwrite actualDraft

                    else
                        ( sessionWithActualDraft, Cmd.none )

        Nothing ->
            ( sessionWithActualDraft, Cmd.none )


gotActualSolution : SolutionId -> Maybe Solution -> Session -> ( Session, Cmd msg )
gotActualSolution solutionId maybeActualSolution oldSession =
    let
        newSession =
            oldSession.solutions
                |> RemoteCache.withActualValue solutionId maybeActualSolution
                |> flip Session.withSolutionCache oldSession
    in
    case maybeActualSolution of
        Just actualSolution ->
            newSession.solutions
                |> RemoteCache.withLocalValue solutionId (Just actualSolution)
                |> RemoteCache.withExpectedValue solutionId (Just actualSolution)
                |> flip Session.withSolutionCache newSession
                |> withCmd (Solution.saveRemoteToLocalStorage actualSolution)
                |> withExtraCmd (Solution.saveToLocalStorage actualSolution)

        Nothing ->
            ( newSession, Cmd.none )
