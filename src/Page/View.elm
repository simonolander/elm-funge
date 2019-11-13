module Page.View exposing (view)

import Data.Session exposing (Session)
import Html exposing (Html)
import Page.Blueprint.View
import Page.Blueprints.View
import Page.Campaign.View
import Page.Campaigns.View
import Page.Credits.View
import Page.Draft.View
import Page.Execution.View
import Page.Home.View
import Page.Model exposing (PageModel(..))
import Page.PageMsg exposing (PageMsg(..))


view : Session -> PageModel -> ( String, Html PageMsg )
view session pageModel =
    Tuple.mapSecond (Html.map InternalMsg) <|
        case pageModel of
            Home model ->
                Page.Home.View.view session model

            Campaign model ->
                Page.Campaign.View.view session model

            Campaigns model ->
                Page.Campaigns.View.view session model

            Credits model ->
                Page.Credits.View.view session model

            Execution model ->
                Page.Execution.View.view session model

            Draft model ->
                Page.Draft.View.view session model

            Blueprint model ->
                Page.Blueprint.View.view session model

            Blueprints model ->
                Page.Blueprints.View.view session model
