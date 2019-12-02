module Page.Model exposing (Model(..))

import Page.Blueprint.Model
import Page.Blueprints.Model
import Page.Campaign.Model
import Page.Campaigns.Model
import Page.Credits.Model
import Page.Draft.Model
import Page.Execution.Model
import Page.Home.Model
import Page.NotFound.Model


type Model
    = BlueprintModel Page.Blueprint.Model.Model
    | BlueprintsModel Page.Blueprints.Model.Model
    | CampaignModel Page.Campaign.Model.Model
    | CampaignsModel Page.Campaigns.Model.Model
    | CreditsModel Page.Credits.Model.Model
    | DraftModel Page.Draft.Model.Model
    | ExecutionModel Page.Execution.Model.Model
    | HomeModel Page.Home.Model.Model
    | NotFoundModel Page.NotFound.Model.Model
