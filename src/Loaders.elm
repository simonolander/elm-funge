module Loaders exposing (loadBlueprintByBlueprintId, loadBlueprints, loadCampaignByCampaignId, loadCampaignsByCampaignIds, loadDraftsByLevelId, loadHighScoreByLevelId, loadLevelsByCampaignId, loadSolutionsByCampaignId, loadSolutionsByCampaignIds)

import Basics.Extra exposing (flip)
import Data.Blueprint as Blueprint
import Data.BlueprintBook as BlueprintBook
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache
import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.Draft as Draft
import Data.DraftBook as DraftBook
import Data.DraftId exposing (DraftId)
import Data.HighScore as HighScore
import Data.Level as Level
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache
import Data.Session as Session exposing (Session)
import Data.Solution as Solution
import Data.SolutionBook as SolutionBook
import Data.SolutionId exposing (SolutionId)
import Extra.Cmd
import RemoteData exposing (RemoteData(..))
import SessionUpdate exposing (SessionMsg(..))
import Set


loadCampaignByCampaignId : CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadCampaignByCampaignId campaignId session =
    case Cache.get campaignId session.campaigns of
        NotAsked ->
            let
                loadCampaignRemotely =
                    Level.loadFromServerByCampaignId (GotLoadLevelsByCampaignIdResponse campaignId) campaignId
            in
            ( Cache.loading campaignId session.campaigns
                |> flip Session.withCampaignCache session
            , loadCampaignRemotely
            )

        _ ->
            ( session, Cmd.none )


loadCampaignsByCampaignIds : List CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadCampaignsByCampaignIds campaignIds =
    Extra.Cmd.fold (List.map loadCampaignByCampaignId campaignIds)


loadLevelsByCampaignId : CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadLevelsByCampaignId campaignId session =
    case
        Session.getCampaign campaignId session
            |> RemoteData.toMaybe
    of
        Just campaign ->
            let
                notAskedLevelIds =
                    campaign.levelIds
                        |> List.filter (flip Cache.isNotAsked session.levels)
            in
            ( List.foldl Cache.loading session.levels notAskedLevelIds
                |> flip Session.withLevelCache session
            , notAskedLevelIds
                |> List.map (\levelId -> Level.loadFromServer (GotLoadLevelByLevelIdResponse levelId) levelId)
                |> Cmd.batch
            )

        Nothing ->
            ( session, Cmd.none )


loadSolutionsBySolutionIds : List SolutionId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionsBySolutionIds solutionIds session =
    case Session.getAccessToken session of
        Just accessToken ->
            let
                notAskedSolutionIds =
                    List.filter (flip Cache.isNotAsked session.solutions.actual) solutionIds
            in
            ( notAskedSolutionIds
                |> List.foldl RemoteCache.withActualLoading session.solutions
                |> flip Session.withSolutionCache session
            , notAskedSolutionIds
                |> List.map (\solutionId -> Solution.loadFromServerBySolutionId (GotLoadSolutionsBySolutionIdResponse solutionId) accessToken solutionId)
                |> Cmd.batch
            )

        Nothing ->
            let
                notAskedSolutionIds =
                    List.filter (flip Cache.isNotAsked session.solutions.local) solutionIds
            in
            ( notAskedSolutionIds
                |> List.foldl RemoteCache.withLocalLoading session.solutions
                |> flip Session.withSolutionCache session
            , notAskedSolutionIds
                |> List.map Solution.loadFromLocalStorage
                |> Cmd.batch
            )


loadSolutionBooksByLevelIds : List LevelId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionBooksByLevelIds levelIds session =
    case Session.getAccessToken session of
        Just accessToken ->
            ( levelIds
                |> List.foldl Cache.loading session.solutionBooks
                |> flip Session.withSolutionBookCache session
            , if List.isEmpty levelIds then
                Cmd.none

              else
                Solution.loadFromServerByLevelIds
                    (GotLoadSolutionsByLevelIdsResponse levelIds)
                    accessToken
                    levelIds
            )

        Nothing ->
            ( levelIds
                |> List.foldl Cache.loading session.solutionBooks
                |> flip Session.withSolutionBookCache session
            , levelIds
                |> List.map SolutionBook.loadFromLocalStorage
                |> Cmd.batch
            )


loadSolutionsByCampaignId : CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionsByCampaignId campaignId session =
    case Cache.get campaignId session.campaigns of
        Success campaign ->
            let
                notAskedLevelIds =
                    List.filter (flip Cache.isNotAsked session.solutionBooks) campaign.levelIds

                notAskedSolutionIds =
                    List.map (flip Cache.get session.solutionBooks) campaign.levelIds
                        |> List.filterMap RemoteData.toMaybe
                        |> List.concatMap (.solutionIds >> Set.toList)
            in
            Extra.Cmd.fold
                [ loadSolutionBooksByLevelIds notAskedLevelIds
                , loadSolutionsBySolutionIds notAskedSolutionIds
                ]
                session

        _ ->
            ( session, Cmd.none )


loadSolutionsByCampaignIds : List CampaignId -> Session -> ( Session, Cmd SessionMsg )
loadSolutionsByCampaignIds campaignIds =
    Extra.Cmd.fold (List.map loadSolutionsByCampaignId campaignIds)


loadDraftBookByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadDraftBookByLevelId levelId session =
    case Cache.get levelId session.draftBooks of
        NotAsked ->
            ( Cache.loading levelId session.draftBooks
                |> flip Session.withDraftBookCache session
            , case Session.getAccessToken session of
                Just accessToken ->
                    Draft.loadFromServerByLevelId (GotLoadDraftsByLevelIdResponse levelId) accessToken levelId

                Nothing ->
                    DraftBook.loadFromLocalStorage levelId
            )

        _ ->
            ( session, Cmd.none )


loadDraftsByDraftIds : List DraftId -> Session -> ( Session, Cmd SessionMsg )
loadDraftsByDraftIds draftIds session =
    let
        notAskedDraftIds =
            List.filter (flip Cache.isNotAsked session.drafts.local) draftIds
    in
    ( notAskedDraftIds
        |> List.foldl RemoteCache.withLocalLoading session.drafts
        |> flip Session.withDraftCache session
    , notAskedDraftIds
        |> List.map Draft.loadFromLocalStorage
        |> Cmd.batch
    )


loadDraftsByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadDraftsByLevelId levelId session =
    Extra.Cmd.fold
        [ loadDraftBookByLevelId levelId
        , \s ->
            case RemoteData.toMaybe (Cache.get levelId s.draftBooks) of
                Just { draftIds } ->
                    loadDraftsByDraftIds (Set.toList draftIds) s

                Nothing ->
                    ( s, Cmd.none )
        ]
        session


loadHighScoreByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadHighScoreByLevelId levelId session =
    case Cache.get levelId session.highScores of
        NotAsked ->
            ( Cache.loading levelId session.highScores
                |> flip Session.withHighScoreCache session
            , HighScore.loadFromServer levelId (GotLoadHighScoreResponse levelId)
            )

        _ ->
            ( session, Cmd.none )
