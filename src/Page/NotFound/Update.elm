module Page.NotFound.Update exposing (load, update)

import Data.CmdUpdater exposing (CmdUpdater)
import Data.Session exposing (Session)
import Page.NotFound.Model exposing (Model)
import Page.NotFound.Msg exposing (Msg)
import Update.SessionMsg exposing (SessionMsg)


load : CmdUpdater ( Session, Model ) SessionMsg
load ( session, model ) =
    ( ( session, model ), Cmd.none )


update : Msg -> CmdUpdater ( Session, Model ) SessionMsg
update msg ( session, model ) =
    ( ( session, model ), Cmd.none )
