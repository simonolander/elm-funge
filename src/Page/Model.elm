module Page.Model exposing (PageModel(..))

import Page.Blueprint
import Page.Blueprints.Model
import Page.Campaign
import Page.Campaigns
import Page.Credits
import Page.Draft
import Page.Execution
import Page.Home.Model
import Page.Initialize
import Page.NotFound


type PageModel
    = Home Page.Home.Model.Model
    | Campaign Page.Campaign.Model
    | Campaigns Page.Campaigns.Model
    | Credits Page.Credits.Model
    | Execution Page.Execution.Model
    | Draft Page.Draft.Model
    | Blueprint Page.Blueprint.Model
    | Blueprints Page.Blueprints.Model.Model
    | Initialize Page.Initialize.Model
    | NotFound Page.NotFound.Model
