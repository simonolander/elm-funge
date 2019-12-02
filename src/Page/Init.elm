module Page.Init exposing (init)

import Page.Blueprint.Model
import Page.Blueprints.Model
import Page.Campaign.Model
import Page.Campaigns.Model
import Page.Credits.Model
import Page.Draft.Model
import Page.Execution.Model
import Page.Home.Model
import Page.Model exposing (Model(..))
import Page.NotFound.Model
import Route exposing (Route)
import Url exposing (Url)


init : Url -> Model
init url =
    case Route.fromUrl url of
        Just Route.Home ->
            Page.Home.Model.init
                |> HomeModel

        Just (Route.Campaign campaignId maybeLevelId) ->
            Page.Campaign.Model.init campaignId maybeLevelId
                |> CampaignModel

        Just Route.Campaigns ->
            Page.Campaigns.Model.init
                |> CampaignsModel

        Just (Route.EditDraft draftId) ->
            Page.Draft.Model.init draftId
                |> DraftModel

        Just (Route.ExecuteDraft draftId) ->
            Page.Execution.Model.init draftId
                |> ExecutionModel

        Just (Route.Blueprints maybeLevelId) ->
            Page.Blueprints.Model.init maybeLevelId
                |> BlueprintsModel

        Just (Route.Blueprint levelId) ->
            Page.Blueprint.Model.init levelId
                |> BlueprintModel

        Just Route.Credits ->
            Page.Credits.Model.init
                |> CreditsModel

        Nothing ->
            Page.NotFound.Model.init
                |> NotFoundModel
