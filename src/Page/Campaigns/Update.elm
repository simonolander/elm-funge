module Page.Campaigns.Update exposing (load, update)

import Basics.Extra exposing (flip)
import Data.CampaignId as CampaignId
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withModel)
import Data.Session exposing (Session)
import Page.Campaigns.Model exposing (Model)
import Page.Campaigns.Msg exposing (Msg)
import Update.SessionMsg exposing (SessionMsg)
import Update.Solution exposing (loadSolutionsByCampaignIdsResponse)
import Update.Update exposing (loadLevelsByCampaignIds)


load : CmdUpdater ( Session, Model ) SessionMsg
load =
    let
        loadCampaigns ( session, model ) =
            loadLevelsByCampaignIds CampaignId.all session
                |> withModel model

        loadSolutions ( session, model ) =
            loadSolutionsByCampaignIdsResponse CampaignId.all session
                |> withModel model
    in
    CmdUpdater.batch
        [ loadCampaigns
        , loadSolutions
        ]


update : Msg -> CmdUpdater ( Session, Model ) SessionMsg
update =
    always (flip Tuple.pair Cmd.none)
