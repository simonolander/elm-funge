module Page.Mapping exposing (sessionLoad, useModel)

import Basics.Extra exposing (flip)
import Data.Session exposing (Session)
import Page.PageMsg exposing (PageMsg(..))
import Update.SessionMsg exposing (SessionMsg)



-- TODO We probably don't need this


sessionLoad : (Session -> ( Session, Cmd SessionMsg )) -> ( Session, b ) -> ( ( Session, b ), Cmd PageMsg )
sessionLoad function ( session, b ) =
    Tuple.mapBoth (flip Tuple.pair b) (Cmd.map SessionMsg) (function session)


useModel : (b -> (Session -> ( Session, Cmd SessionMsg ))) -> ( Session, b ) -> ( ( Session, b ), Cmd PageMsg )
useModel getUpdate ( session, model ) =
    sessionLoad (getUpdate model) ( session, model )
