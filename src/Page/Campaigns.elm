module Page.Campaigns exposing (Model, Msg(..), init, load, subscriptions, update, view)

import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Cache as Cache
import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.Level as Level
import Data.Session as Session exposing (Session)
import Data.Solution as Solution
import Data.SolutionBook
import Element exposing (..)
import Extra.Cmd
import Html
import List.Extra
import Loaders
import RemoteData exposing (RemoteData(..))
import Route
import SessionUpdate exposing (SessionMsg(..))
import Set
import String.Extra
import View.Card as Card
import View.Constant exposing (icons, size)
import View.Header
import View.Scewn as Scewn



-- MODEL


type alias Model =
    { session : Session
    }


withSession : Session -> Model -> Model
withSession session model =
    { model | session = session }


type Msg
    = InternalMsg InternalMsg
    | SessionMsg SessionMsg


type alias InternalMsg =
    ()


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadCampaigns model =
            Loaders.loadCampaignsByCampaignIds CampaignId.all model.session
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

        loadSolutions model =
            Loaders.loadSolutionsByCampaignIds CampaignId.all model.session
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)
    in
    Extra.Cmd.fold
        [ loadCampaigns
        , loadSolutions
        ]



-- UPDATE


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            Scewn.layout
                { south = Nothing
                , center = Just <| viewCampaigns model
                , east = Nothing
                , west = Nothing
                , north = Just <| View.Header.view model.session
                , modal = Nothing
                }
    in
    { body =
        List.map (Html.map InternalMsg) [ content ]
    , title = "Campaigns"
    }


viewCampaigns : Model -> Element InternalMsg
viewCampaigns model =
    let
        campaigns =
            CampaignId.all
                |> List.map (viewCampaign model)
    in
    column
        [ width (maximum 1000 fill)
        , centerX
        , spacing 20
        ]
        campaigns


viewCampaign : Model -> CampaignId -> Element InternalMsg
viewCampaign model campaignId =
    let
        title =
            String.Extra.toSentenceCase campaignId
    in
    case Cache.get campaignId model.session.campaigns of
        NotAsked ->
            text (title ++ ": NotAsked")

        Loading ->
            text (title ++ ": Loading")

        Failure error ->
            text (title ++ ": Failure")

        Success campaign ->
            let
                numberOfLevels =
                    List.length campaign.levelIds

                solutionBooks =
                    List.map (flip Cache.get model.session.solutionBooks) campaign.levelIds

                numberOfLoadingLevels =
                    List.Extra.count RemoteData.isLoading solutionBooks

                numberOfSolvedLevels =
                    List.filterMap RemoteData.toMaybe solutionBooks
                        |> List.Extra.count (.solutionIds >> Set.isEmpty >> not)

                content =
                    if numberOfLoadingLevels > 0 then
                        column
                            [ width fill, spacing 20 ]
                            [ text title
                            , image [ width (px 20) ] { src = icons.spinner, description = "Loading" }
                            ]

                    else
                        column
                            [ width fill, spacing 20 ]
                            [ el [ size.font.card.title, centerX ] (text title)
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
