module Page.Campaign.Update exposing (load, update)

import Basics.Extra exposing (flip)
import Data.Cache as Cache
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withModel)
import Data.Draft as Draft
import Data.Session exposing (Session)
import Page.Campaign.Model exposing (Model)
import Page.Campaign.Msg exposing (Msg(..))
import Page.Msg
import Random
import RemoteData exposing (RemoteData(..))
import Resource.Draft.Update exposing (loadDraftsByLevelId, saveDraft)
import Route
import Update.HighScore exposing (loadHighScoreByLevelId)
import Update.SessionMsg exposing (SessionMsg)
import Update.Update exposing (loadLevelsByCampaignId)


load : CmdUpdater ( Session, Model ) SessionMsg
load =
    let
        loadLevels ( session, model ) =
            loadLevelsByCampaignId model.campaignId session
                |> withModel model

        loadSolutions ( session, model ) =
            loadSolutions model.campaignId session
                |> withModel model

        loadDraftsBySelectedLevelId ( session, model ) =
            case model.selectedLevelId of
                Just levelId ->
                    loadDraftsByLevelId levelId session
                        |> withModel model

                Nothing ->
                    ( ( session, model ), Cmd.none )

        loadSelectedLevelHighScore ( session, model ) =
            case model.selectedLevelId of
                Just levelId ->
                    loadHighScoreByLevelId levelId session
                        |> withModel model

                Nothing ->
                    ( ( session, model ), Cmd.none )
    in
    CmdUpdater.batch
        [ loadLevels
        , loadSolutions
        , loadDraftsBySelectedLevelId
        , loadSelectedLevelHighScore
        ]


update : Msg -> ( Session, Model ) -> ( ( Session, Model ), Cmd Page.Msg.Msg )
update msg tuple =
    let
        ( session, model ) =
            tuple

        fromMsg =
            CmdUpdater.mapCmd (Page.Msg.CampaignMsg >> Page.Msg.PageMsg)

        fromSessionMsg =
            CmdUpdater.mapCmd Page.Msg.SessionMsg
    in
    case msg of
        ClickedLevel selectedLevelId ->
            fromMsg <|
                ( ( session, { model | selectedLevelId = Just selectedLevelId } )
                , Route.replaceUrl session.key (Route.Campaign model.campaignId (Just selectedLevelId))
                )

        ClickedOpenDraft draftId ->
            fromMsg <|
                ( tuple
                , Route.pushUrl session.key (Route.EditDraft draftId)
                )

        ClickedGenerateDraft ->
            fromMsg <|
                case
                    Maybe.map (flip Cache.get session.levels) model.selectedLevelId
                        |> Maybe.andThen RemoteData.toMaybe
                of
                    Just level ->
                        ( tuple, Random.generate GeneratedDraft (Draft.generator level) )

                    Nothing ->
                        ( tuple, Cmd.none )

        GeneratedDraft draft ->
            fromSessionMsg <|
                saveDraft draft session
                    |> withModel model
                    |> CmdUpdater.add (Route.pushUrl session.key (Route.EditDraft draft.id))
