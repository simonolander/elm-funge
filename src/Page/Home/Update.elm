module Page.Home.Update exposing (load, update)

import Basics.Extra exposing (flip)
import Data.CmdUpdater exposing (CmdUpdater)
import Data.Session exposing (Session)
import Page.Home.Model exposing (Model)
import Page.Home.Msg exposing (Msg)
import Update.SessionMsg exposing (SessionMsg)


load : CmdUpdater ( Session, Model ) SessionMsg
load =
    flip Tuple.pair Cmd.none


update : Msg -> CmdUpdater ( Session, Model ) SessionMsg
update =
    always (flip Tuple.pair Cmd.none)
