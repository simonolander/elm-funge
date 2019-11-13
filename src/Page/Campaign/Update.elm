module Page.Campaign.Update exposing (init)

import Basics.Extra exposing (flip)
import Data.Cache as Cache
import Data.CampaignId exposing (CampaignId)
import Data.CmdUpdater as CmdUpdater
import Data.Draft as Draft
import Data.LevelId exposing (LevelId)
import Data.Session exposing (Session)
import Page.Campaign.Model exposing (Model)
import Page.Campaign.Msg exposing (Msg(..))
import Page.Mapping exposing (useModel)
import Page.PageMsg exposing (PageMsg)
import Random
import RemoteData exposing (RemoteData(..))
import Route
import Update.Draft exposing (loadDraftsByLevelId, saveDraft)
import Update.HighScore exposing (loadHighScoreByLevelId)
import Update.Level exposing (loadLevelsByCampaignId)


init : CampaignId -> Maybe LevelId -> ( Model, Cmd Msg )
init campaignId selectedLevelId =
    let
        model =
            { campaignId = campaignId
            , selectedLevelId = selectedLevelId
            }
    in
    ( model, Cmd.none )


load : ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
load =
    let
        loadLevels model =
            loadLevelsByCampaignId model.campaignId

        loadSolutions model =
            loadSolutions model.campaignId

        loadDraftsBySelectedLevelId model =
            case model.selectedLevelId of
                Just levelId ->
                    loadDraftsByLevelId levelId

                Nothing ->
                    flip Tuple.pair Cmd.none

        loadSelectedLevelHighScore model =
            case model.selectedLevelId of
                Just levelId ->
                    loadHighScoreByLevelId levelId

                Nothing ->
                    flip Tuple.pair Cmd.none
    in
    CmdUpdater.batch
        [ useModel loadLevels
        , useModel loadSolutions
        , useModel loadDraftsBySelectedLevelId
        , useModel loadSelectedLevelHighScore
        ]


update : Msg -> ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
update msg tuple =
    let
        ( session, model ) =
            tuple
    in
    case msg of
        ClickedLevel selectedLevelId ->
            ( ( session, { model | selectedLevelId = Just selectedLevelId } )
            , Route.replaceUrl session.key (Route.Campaign model.campaignId (Just selectedLevelId))
            )

        ClickedOpenDraft draftId ->
            ( tuple
            , Route.pushUrl session.key (Route.EditDraft draftId)
            )

        ClickedGenerateDraft ->
            case
                Maybe.map (flip Cache.get session.levels) model.selectedLevelId
                    |> Maybe.andThen RemoteData.toMaybe
            of
                Just level ->
                    ( tuple, Random.generate GeneratedDraft (Draft.generator level) )

                Nothing ->
                    ( tuple, Cmd.none )

        GeneratedDraft draft ->
            Page.Mapping.sessionLoad (saveDraft draft) tuple
                |> CmdUpdater.add (Route.pushUrl session.key (Route.EditDraft draft.id))
