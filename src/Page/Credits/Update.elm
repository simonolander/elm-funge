module Page.Credits.Update exposing (load, update)

import Basics.Extra exposing (flip)
import Data.Session exposing (Session)
import Page.Credits.Model exposing (Model)
import Page.Credits.Msg exposing (Msg)
import Page.PageMsg exposing (PageMsg)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


load : ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
load =
    flip Tuple.pair Cmd.none
