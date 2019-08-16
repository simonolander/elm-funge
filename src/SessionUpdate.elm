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
import Data.SubmitSolutionError as SubmitSolutionError exposing (SubmitSolutionError)
import Dict
import Dict.Extra
import Extra.Cmd exposing (withCmd, withExtraCmd)
import Extra.Result
import Maybe.Extra
import Ports.Console
import Random
import RemoteData exposing (RemoteData(..))
import Set


type SessionMsg
    = GeneratedSolution Solution
    | GotDeleteDraftResponse DraftId (Maybe SaveError)
    | GotLoadDraftByDraftIdResponse DraftId (Result GetError (Maybe Draft))
    | GotLoadDraftsByLevelIdResponse LevelId (Result GetError (List Draft))
    | GotLoadHighScoreResponse LevelId (Result GetError HighScore)
    | GotLoadLevelByLevelIdResponse LevelId (Result GetError Level)
    | GotLoadLevelsByCampaignIdResponse CampaignId (Result GetError (List Level))
    | GotLoadSolutionsByLevelIdResponse LevelId (Result GetError (List Solution))
    | GotLoadSolutionsByLevelIdsResponse (List LevelId) (Result GetError (List Solution))
    | GotLoadSolutionsBySolutionIdResponse SolutionId (Result GetError (Maybe Solution))
    | GotSaveDraftResponse Draft (Maybe SaveError)
    | GotSaveSolutionResponse Solution (Maybe SubmitSolutionError)


update : SessionMsg -> Session -> ( Session, Cmd SessionMsg )
update msg session =
    case msg of
        GeneratedSolution solution ->
            let
                solutionCache =
                    session.solutions
                        |> RemoteCache.withActualValue solution.id (Just solution)

                solutionBookCache =
                    session.solutionBooks
                        |> Cache.update solution.id (RemoteData.map (SolutionBook.withSolutionId solution.id))

                cmd =
                    [ Just <| Solution.saveToLocalStorage solution
                    , Just <| SolutionBook.saveToLocalStorage solution.id solution.levelId
                    , Session.getAccessToken session
                        |> Maybe.map (flip (Solution.saveToServer (GotSaveSolutionResponse solution)) solution)
                    ]
                        |> Maybe.Extra.values
                        |> Cmd.batch
            in
            session
                |> Session.withSolutionCache solutionCache
                |> Session.withSolutionBookCache solutionBookCache
                |> withCmd cmd

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

        GotLoadSolutionsBySolutionIdResponse solutionId result ->
            case result of
                Ok solution ->
                    gotActualSolution solutionId solution session

                Err error ->
                    session.solutions
                        |> RemoteCache.withActualError solutionId error
                        |> RemoteCache.withLocalLoading solutionId
                        |> flip Session.withSolutionCache session
                        |> withCmd (Solution.loadFromLocalStorage solutionId)
                        |> withExtraCmd (GetError.consoleError error)

        GotLoadSolutionsByLevelIdResponse levelId result ->
            case result of
                Ok solutions ->
                    gotSolutionsByLevelId levelId solutions session

                Err error ->
                    session.solutionBooks
                        |> Cache.loading levelId
                        |> flip Session.withSolutionBookCache session
                        |> withCmd (SolutionBook.loadFromLocalStorage levelId)
                        |> withExtraCmd (GetError.consoleError error)

        GotLoadSolutionsByLevelIdsResponse levelIds result ->
            case result of
                Ok solutions ->
                    solutions
                        |> Dict.Extra.groupBy .levelId
                        |> Dict.toList
                        |> List.map (\( levelId, solutionsByLevelId ) -> gotSolutionsByLevelId levelId solutionsByLevelId)
                        |> flip Extra.Cmd.fold session

                Err error ->
                    let
                        functions =
                            List.map
                                (\levelId sess ->
                                    sess.solutionBooks
                                        |> Cache.loading levelId
                                        |> flip Session.withSolutionBookCache sess
                                        |> withCmd (SolutionBook.loadFromLocalStorage levelId)
                                        |> withExtraCmd (GetError.consoleError error)
                                )
                                levelIds
                    in
                    Extra.Cmd.fold functions session

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
                    case error of
                        SubmitSolutionError.NetworkError ->
                            Debug.todo "Offline"

                        SubmitSolutionError.InvalidAccessToken message ->
                            ( Session.withoutAccessToken session, Ports.Console.errorString message )

                        SubmitSolutionError.Duplicate ->
                            let
                                solutionCache =
                                    session.solutions
                                        |> RemoteCache.withLocalValue solution.id Nothing
                                        |> RemoteCache.withExpectedValue solution.id Nothing
                                        |> RemoteCache.withActualValue solution.id Nothing

                                solutionBookCache =
                                    session.solutionBooks
                                        |> Cache.update solution.id (RemoteData.map (SolutionBook.withoutSolutionId solution.id))

                                cmd =
                                    Cmd.batch
                                        [ Solution.removeFromLocalStorage solution.id
                                        , Solution.removeRemoteFromLocalStorage solution.id
                                        , SolutionBook.removeSolutionIdFromLocalStorage solution.id solution.levelId
                                        ]
                            in
                            session
                                |> Session.withSolutionCache solutionCache
                                |> Session.withSolutionBookCache solutionBookCache
                                |> withCmd cmd

                        SubmitSolutionError.ConflictingId ->
                            let
                                solutionCache =
                                    session.solutions
                                        |> RemoteCache.withLocalValue solution.id Nothing
                                        |> RemoteCache.withExpectedValue solution.id Nothing
                                        |> RemoteCache.withActualValue solution.id Nothing

                                solutionBookCache =
                                    session.solutionBooks
                                        |> Cache.update solution.id (RemoteData.map (SolutionBook.withoutSolutionId solution.id))

                                cmd =
                                    Cmd.batch
                                        [ Solution.removeFromLocalStorage solution.id
                                        , Solution.removeRemoteFromLocalStorage solution.id
                                        , SolutionBook.removeSolutionIdFromLocalStorage solution.id solution.levelId
                                        , Solution.generator solution.levelId solution.score solution.board
                                            |> Random.generate GeneratedSolution
                                        ]
                            in
                            session
                                |> Session.withSolutionCache solutionCache
                                |> Session.withSolutionBookCache solutionBookCache
                                |> withCmd cmd

                        SubmitSolutionError.Other _ ->
                            ( session, SubmitSolutionError.consoleError error )


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


gotSolutionsByLevelId : LevelId -> List Solution -> Session -> ( Session, Cmd SessionMsg )
gotSolutionsByLevelId levelId solutions session =
    let
        solutionBookCache =
            session.solutionBooks
                |> Cache.update levelId
                    (RemoteData.withDefault (SolutionBook.empty levelId)
                        >> SolutionBook.withSolutionIds
                            (solutions
                                |> List.map .id
                                |> Set.fromList
                            )
                        >> Success
                    )
    in
    session
        |> Session.withSolutionBookCache solutionBookCache
        |> Extra.Cmd.fold (List.map (\solution -> gotActualSolution solution.id (Just solution)) solutions)
