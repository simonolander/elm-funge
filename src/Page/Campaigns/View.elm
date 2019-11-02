module Page.Campaigns.View exposing (view, viewCampaign, viewCampaigns)

import ApplicationName exposing (applicationName)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Cache as Cache
import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.GetError as GetError
import Data.Session exposing (Session)
import Element exposing (..)
import List.Extra
import Page.Campaigns.Model exposing (Model)
import Page.Campaigns.Msg exposing (Msg)
import RemoteData exposing (RemoteData(..))
import Route
import String.Extra
import View.Card as Card
import View.Constant exposing (icons, size)
import View.Header
import View.Scewn as Scewn


view : ( Session, Model ) -> Document Msg
view ( session, _ ) =
    let
        content =
            Scewn.layout
                { south = Nothing
                , center = Just <| viewCampaigns session
                , east = Nothing
                , west = Nothing
                , north = Just <| View.Header.view session
                , modal = Nothing
                }
    in
    { body = [ content ]
    , title = "Campaigns"
    }


viewCampaigns : Session -> Element Msg
viewCampaigns session =
    let
        title =
            el [ size.font.page.title, centerX, padding 20 ] (text "Campaigns")

        campaigns =
            CampaignId.all
                |> List.map (viewCampaign session)

        elements =
            List.concat
                [ [ title ]
                , campaigns
                ]
    in
    column
        [ width (maximum 1000 fill)
        , centerX
        , spacing 20
        , padding 60
        ]
        elements


viewCampaign : Session -> CampaignId -> Element Msg
viewCampaign session campaignId =
    let
        title =
            String.Extra.toSentenceCase campaignId
                |> text
                |> el [ size.font.card.title, centerX ]
    in
    case Cache.get campaignId session.campaignRequests of
        NotAsked ->
            Card.link
                { url = Route.toString (Route.Campaign campaignId Nothing)
                , content =
                    column
                        [ width fill, spacing 20 ]
                        [ title
                        , text "Request not sent"
                        ]
                , marked = False
                , selected = False
                }

        Loading ->
            Card.link
                { url = Route.toString (Route.Campaign campaignId Nothing)
                , content =
                    column
                        [ width fill, spacing 20 ]
                        [ title
                        , image [ width (px 20), centerX ] { src = icons.spinner, description = "Loading" }
                        ]
                , marked = False
                , selected = False
                }

        Failure error ->
            Card.link
                { url = Route.toString (Route.Campaign campaignId Nothing)
                , content =
                    column
                        [ width fill, spacing 20 ]
                        [ title
                        , text (GetError.toString error)
                        ]
                , marked = False
                , selected = False
                }

        Success () ->
            let
                campaignLevels =
                    Cache.values session.levels
                        |> List.filterMap RemoteData.toMaybe
                        |> List.filter (.campaignId >> (==) campaignId)

                numberOfLevels =
                    List.length campaignLevels

                solutionBooks =
                    List.map (flip Cache.get session.solutionBooks) campaign.levelIds

                numberOfLoadingLevels =
                    List.Extra.count RemoteData.isLoading solutionBooks

                numberOfSolvedLevels =
                    List.filterMap RemoteData.toMaybe solutionBooks
                        |> List.Extra.count (.solutionIds >> Set.isEmptzy >> not)

                content =
                    if numberOfLoadingLevels > 0 then
                        column
                            [ width fill, spacing 20 ]
                            [ title
                            , row [ centerX ]
                                [ image [ width (px 20) ] { src = icons.spinner, description = "Loading" }
                                , text " /"
                                , text (String.fromInt numberOfLevels)
                                ]
                            ]

                    else
                        column
                            [ width fill, spacing 20 ]
                            [ title
                            , row [ centerX ]
                                [ text (String.fromInt numberOfSolvedLevels)
                                , text "/"
                                , text (String.fromInt numberOfLevels)
                                ]
                            ]
            in
            Card.link
                { url = Route.toString (Route.Campaign campaignId Nothing)
                , content = content
                , marked = numberOfLevels == numberOfSolvedLevels
                , selected = False
                }
