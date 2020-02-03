module Page.View exposing (view)

import Data.Session exposing (Session)
import Element exposing (Element)
import Html exposing (Html)
import Page.Blueprint.View
import Page.Blueprints.View
import Page.Campaign.View
import Page.Campaigns.View
import Page.Credits.View
import Page.Draft.View
import Page.Execution.View
import Page.Home.View
import Page.Model exposing (Model(..))
import Page.Msg exposing (PageMsg)
import Page.NotFound.View


view : Session -> Model -> ( String, Element PageMsg )
view session pageModel =
    Tuple.mapSecond (Html.map PageMsg) <|
        case pageModel of
            HomeModel model ->
                Page.Home.View.view session model

            CampaignModel model ->
                Page.Campaign.View.view session model

            CampaignsModel model ->
                Page.Campaigns.View.view session model

            CreditsModel model ->
                Page.Credits.View.view session model

            ExecutionModel model ->
                Page.Execution.View.view session model

            DraftModel model ->
                Page.Draft.View.view session model

            BlueprintModel model ->
                Page.Blueprint.View.view session model

            BlueprintsModel model ->
                Page.Blueprints.View.view session model

            NotFoundModel model ->
                Page.NotFound.View.view session model
