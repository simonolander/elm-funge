module Page.Msg exposing (Msg(..), PageMsg(..))

import Page.Blueprint.Msg
import Page.Blueprints.Msg
import Page.Campaign.Msg
import Page.Campaigns.Msg
import Page.Credits.Msg
import Page.Draft.Msg
import Page.Execution.Msg
import Page.Home.Msg
import Page.NotFound.Msg
import Update.SessionMsg exposing (SessionMsg)


type PageMsg
    = BlueprintMsg Page.Blueprint.Msg.Msg
    | BlueprintsMsg Page.Blueprints.Msg.Msg
    | CampaignMsg Page.Campaign.Msg.Msg
    | CampaignsMsg Page.Campaigns.Msg.Msg
    | CreditsMsg Page.Credits.Msg.Msg
    | DraftMsg Page.Draft.Msg.Msg
    | ExecutionMsg Page.Execution.Msg.Msg
    | HomeMsg Page.Home.Msg.Msg
    | NotFoundMsg Page.NotFound.Msg.Msg


type Msg
    = SessionMsg SessionMsg
    | PageMsg PageMsg
