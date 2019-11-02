module Page.PageMsg exposing (InternalMsg(..), PageMsg(..))

import Page.Blueprints.Msg as Blueprints
import Update.SessionMsg exposing (SessionMsg)


type InternalMsg
    = Blueprints Blueprints.Msg


type PageMsg
    = SessionMsg SessionMsg
    | InternalMsg InternalMsg
