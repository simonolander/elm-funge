module Page.Model exposing (PageModel(..))

import Page.Blueprint.Model as Blueprint
import Page.Blueprints.Model as Blueprints
import Page.Campaign.Model as Campaign
import Page.Campaigns.Model as Campaigns
import Page.Credits.Model as Credits
import Page.Draft.Model as Draft
import Page.Execution.Model as Execution
import Page.Home.Model as Home


type PageModel
    = Home Home.Model
    | Campaign Campaign.Model
    | Campaigns Campaigns.Model
    | Credits Credits.Model
    | Execution Execution.Model
    | Draft Draft.Model
    | Blueprint Blueprint.Model
    | Blueprints Blueprints.Model
