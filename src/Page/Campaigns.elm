module Page.Campaigns exposing (Model, Msg(..), init, load, subscriptions, update, view)

import Browser exposing (Document)
import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.Session exposing (Session)
import Element exposing (..)
import Html
import SessionUpdate exposing (SessionMsg)
import View.Header
import View.Scewn as Scewn



-- MODEL


type alias Model =
    { session : Session
    }


type Msg
    = InternalMsg InternalMsg
    | SessionMsg SessionMsg


type alias InternalMsg =
    ()


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load model =
    ( model, Cmd.none )



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
    in
    none
