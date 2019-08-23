module Page.Credits exposing (Model, Msg, init, load, subscriptions, update, view)

import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Session exposing (Session)
import Element exposing (..)
import Json.Encode as Encode



-- MODEL


type alias Model =
    { session : Session
    }


type alias Msg =
    ()


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    flip Tuple.pair Cmd.none



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate ( key, value ) model =
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
            layout [] none
    in
    { body = [ content ]
    , title = "Credits"
    }
