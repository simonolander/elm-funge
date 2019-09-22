module Page.Template exposing (Model, Msg(..), init, load, subscriptions, update, view)

import ApplicationName exposing (applicationName)
import Browser exposing (Document)
import Data.Session exposing (Session)
import Element exposing (..)
import Extra.Cmd
import SessionUpdate exposing (SessionMsg)



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
load =
    let
        loadNothing model =
            ( model, Cmd.none )
    in
    Extra.Cmd.fold
        [ loadNothing
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
            layout [] none
    in
    { body = [ content ]
    , title = String.concat [ "Template", " - ", applicationName ]
    }
