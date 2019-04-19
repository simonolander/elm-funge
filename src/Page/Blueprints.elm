module Page.Blueprints exposing (Model, Msg, getSession, init, subscriptions, update, view)

import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Campaign as Campaign
import Data.CampaignId as CampaignId
import Data.Level as Level
import Data.Session as Session exposing (Session)
import Dict
import Element exposing (..)
import Json.Decode as Decode
import Ports.LocalStorage as LocalStorage
import View.SingleSidebar



-- MODEL


type alias Model =
    { session : Session
    }


init : Session -> ( Model, Cmd Msg )
init session =
    let
        cmd =
            case Dict.get CampaignId.blueprints session.campaigns of
                Just campaign ->
                    campaign.levelIds
                        |> List.filter (not << flip Dict.member session.levels)
                        |> List.map Level.loadFromLocalStorage
                        |> Cmd.batch

                Nothing ->
                    Campaign.loadFromLocalStorage CampaignId.blueprints
    in
    ( { session = session }, cmd )


getSession : Model -> Session
getSession { session } =
    session



-- UPDATE


type Msg
    = LocalStorageResponse ( LocalStorage.Key, LocalStorage.Value )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LocalStorageResponse ( key, value ) ->
            if key == Campaign.localStorageKey CampaignId.blueprints then
                case Decode.decodeValue (Decode.maybe Campaign.decoder) value of
                    Ok (Just campaign) ->
                        let
                            newModel =
                                { model | session = Session.withCampaign campaign model.session }

                            cmd =
                                campaign.levelIds
                                    |> List.filter (not << flip Dict.member model.session.levels)
                                    |> List.map Level.loadFromLocalStorage
                                    |> Cmd.batch
                        in
                        ( newModel, cmd )

                    Ok Nothing ->
                        let
                            campaign =
                                Campaign.empty CampaignId.blueprints

                            newModel =
                                { model
                                    | session = Session.withCampaign campaign model.session
                                }

                            cmd =
                                Campaign.saveToLocalStorage campaign
                        in
                        ( newModel, cmd )

                    Err error ->
                        Debug.todo (Decode.errorToString error)

            else
                case Decode.decodeValue (Decode.maybe Level.decoder) value of
                    Ok (Just level) ->
                        let
                            newModel =
                                { model | session = Session.withLevel level model.session }
                        in
                        ( newModel, Cmd.none )

                    Ok Nothing ->
                        Debug.todo ("Level not found: " ++ key)

                    Err error ->
                        Debug.todo (Decode.errorToString error)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    LocalStorage.storageGetItemResponse LocalStorageResponse



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            View.SingleSidebar.view [ none ] [ none ]
    in
    { body = [ content ]
    , title = "Blueprints"
    }
