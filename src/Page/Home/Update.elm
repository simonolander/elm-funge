module Page.Home.Update exposing (init, load, subscriptions, update)

import Basics.Extra exposing (flip)
import Data.Session exposing (Session)
import Page.Home.Model exposing (Model)
import Page.Home.Msg exposing (Msg)
import Page.PageMsg exposing (PageMsg)


init : ( Model, Cmd PageMsg )
init =
    ( (), Cmd.none )


load : ( Session, Model ) -> ( ( Session, Model ), Cmd PageMsg )
load =
    flip Tuple.pair Cmd.none


update : Msg -> Model -> ( Model, Cmd PageMsg )
update =
    always (flip Tuple.pair Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub PageMsg
subscriptions =
    always Sub.none
