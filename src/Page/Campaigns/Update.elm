module Page.Campaigns.Update exposing (init)

import Basics.Extra exposing (flip)
import Data.CampaignId as CampaignId
import Data.Session exposing (Session)
import Extra.Cmd exposing (fold)
import Page.Campaigns.Model exposing (Model)
import Page.Campaigns.Msg exposing (Msg)
import Page.Mapping
import Page.PageMsg exposing (PageMsg)
import Update.Level exposing (loadLevelsByCampaignIds)
import Update.Solution exposing (loadSolutionsByCampaignIdsResponse)


init : ( Model, Cmd msg )
init =
    ( (), Cmd.none )


load : ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
load =
    let
        loadCampaigns =
            Page.Mapping.sessionLoad (loadLevelsByCampaignIds CampaignId.all)

        loadSolutions =
            Page.Mapping.sessionLoad (loadSolutionsByCampaignIdsResponse CampaignId.all)
    in
    fold
        [ loadCampaigns
        , loadSolutions
        ]


update : Msg -> ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
update =
    always (flip Tuple.pair Cmd.none)
