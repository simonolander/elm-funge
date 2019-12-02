module Page.Credits.Update exposing (load, update)

import Basics.Extra exposing (flip)
import Data.CmdUpdater exposing (CmdUpdater)
import Data.Session exposing (Session)
import Page.Credits.Model exposing (Model)
import Page.Credits.Msg exposing (Msg)
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> CmdUpdater ( Session, Model ) SessionMsg
update msg tuple =
    ( tuple, Cmd.none )


load : CmdUpdater ( Session, Model ) SessionMsg
load =
    flip Tuple.pair Cmd.none
