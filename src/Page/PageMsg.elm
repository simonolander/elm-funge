module Page.PageMsg exposing (InternalMsg(..), PageMsg(..))

import Page.Blueprints.Msg as Blueprints
import Page.Campaign.Msg as Campaign
import Page.Campaigns.Msg as Campaigns
import Page.Credits.Msg as Credits
import Page.Draft.Msg as Draft
import Page.Home.Msg as Home
import Update.SessionMsg exposing (SessionMsg)


type InternalMsg
    = Blueprints Blueprints.Msg
    | Campaign Campaign.Msg
    | Campaigns Campaigns.Msg
    | Draft Draft.Msg
    | Home Home.Msg
    | Credits Credits.Msg


type PageMsg
    = SessionMsg SessionMsg
    | InternalMsg InternalMsg
