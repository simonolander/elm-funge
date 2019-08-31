module Page.Template exposing (Model, Msg(..), init, load, subscriptions, update, view)

import Browser exposing (Document)
import Data.Session exposing (Session)
import Element exposing (..)



-- MODEL


type alias Model =
    { session : Session
    }


type Msg
    = InternalMsg InternalMsg
    | SessionMsg Session


type alias InternalMsg =
    ()


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }, Cmd.none )


load : Session -> ( Session, Cmd Msg )
load session =
    ( session, Cmd.none )



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
            layout [] none
    in
    { body = [ content ]
    , title = "Template"
    }
