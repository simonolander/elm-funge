module Page.Blueprint exposing (Model, Msg, getSession, init, localStorageResponseUpdate, subscriptions, update, view)

import Browser exposing (Document)
import Data.LevelId exposing (LevelId)
import Data.Session exposing (Session)
import Element exposing (..)
import Json.Encode as Encode



-- MODEL


type alias Model =
    { session : Session
    , levelId : LevelId
    }


init : LevelId -> Session -> ( Model, Cmd Msg )
init levelId session =
    let
        model =
            { session = session
            , levelId = levelId
            }
    in
    ( model, Cmd.none )


getSession : Model -> Session
getSession { session } =
    session



-- UPDATE


type alias Msg =
    ()


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
    , title = "Blueprint"
    }
