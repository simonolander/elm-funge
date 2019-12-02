module Page.Load exposing (load)

import Data.CmdUpdater as CmdUpdate exposing (CmdUpdater, mapModel)
import Data.Session exposing (Session)
import Page.Blueprint.Update
import Page.Blueprints.Update
import Page.Campaign.Update
import Page.Campaigns.Update
import Page.Credits.Update
import Page.Draft.Update
import Page.Execution.Update
import Page.Home.Update
import Page.Model exposing (Model(..))
import Page.Msg exposing (Msg(..))
import Page.NotFound.Update


load : CmdUpdater ( Session, Model ) Msg
load ( session, pageModel ) =
    CmdUpdate.mapCmd SessionMsg <|
        case pageModel of
            BlueprintModel model ->
                Page.Blueprint.Update.load ( session, model )
                    |> mapModel BlueprintModel

            BlueprintsModel model ->
                Page.Blueprints.Update.load ( session, model )
                    |> mapModel BlueprintsModel

            CampaignModel model ->
                Page.Campaign.Update.load ( session, model )
                    |> mapModel CampaignModel

            CampaignsModel model ->
                Page.Campaigns.Update.load ( session, model )
                    |> mapModel CampaignsModel

            CreditsModel model ->
                Page.Credits.Update.load ( session, model )
                    |> mapModel CreditsModel

            DraftModel model ->
                Page.Draft.Update.load ( session, model )
                    |> mapModel DraftModel

            ExecutionModel model ->
                Page.Execution.Update.load ( session, model )
                    |> mapModel ExecutionModel

            HomeModel model ->
                Page.Home.Update.load ( session, model )
                    |> mapModel HomeModel

            NotFoundModel model ->
                Page.NotFound.Update.load ( session, model )
                    |> mapModel NotFoundModel
