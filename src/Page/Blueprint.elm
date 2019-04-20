module Page.Blueprint exposing (Model, Msg, getSession, init, subscriptions, update, view)

import Browser exposing (Document)
import Data.Session exposing (Session)
import Element exposing (..)



-- MODEL


type alias Model =
    { session : Session
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }, Cmd.none )


getSession : Model -> Session
getSession { session } =
    session



-- UPDATE


type alias Msg =
    ()


update : Msg -> Model -> ( Model, Cmd Msg )
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
    , title = "Blueprint"
    }
