module Page.Update exposing (update)

import Data.CmdUpdater exposing (CmdUpdater, mapCmd, mapModel)
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
import Page.Msg exposing (Msg(..), PageMsg(..))
import Page.NotFound.Update


update : PageMsg -> CmdUpdater ( Session, Model ) Msg
update pageMsg ( session, pageModel ) =
    case ( pageMsg, pageModel ) of
        ( BlueprintMsg msg, BlueprintModel model ) ->
            Page.Blueprint.Update.update msg ( session, model )
                |> mapModel BlueprintModel
                |> mapCmd SessionMsg

        ( BlueprintsMsg msg, BlueprintsModel model ) ->
            Page.Blueprints.Update.update msg ( session, model )
                |> mapModel BlueprintsModel

        ( CampaignMsg msg, CampaignModel model ) ->
            Page.Campaign.Update.update msg ( session, model )
                |> mapModel CampaignModel

        ( CampaignsMsg msg, CampaignsModel model ) ->
            Page.Campaigns.Update.update msg ( session, model )
                |> mapModel CampaignsModel
                |> mapCmd SessionMsg

        ( CreditsMsg msg, CreditsModel model ) ->
            Page.Credits.Update.update msg ( session, model )
                |> mapModel CreditsModel
                |> mapCmd SessionMsg

        ( DraftMsg msg, DraftModel model ) ->
            Page.Draft.Update.update msg ( session, model )
                |> mapModel DraftModel
                |> mapCmd SessionMsg

        ( ExecutionMsg msg, ExecutionModel model ) ->
            Page.Execution.Update.update msg ( session, model )
                |> mapModel ExecutionModel
                |> mapCmd SessionMsg

        ( HomeMsg msg, HomeModel model ) ->
            Page.Home.Update.update msg ( session, model )
                |> mapModel HomeModel
                |> mapCmd SessionMsg

        ( NotFoundMsg msg, NotFoundModel model ) ->
            Page.NotFound.Update.update msg ( session, model )
                |> mapModel NotFoundModel
                |> mapCmd SessionMsg

        _ ->
            Debug.log "Illegal message model combination" ( ( session, pageModel ), Cmd.none )
