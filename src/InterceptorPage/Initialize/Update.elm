module InterceptorPage.Initialize.Update exposing (update)

import Data.Session exposing (Session)
import Debug exposing (todo)
import InterceptorPage.Initialize.Msg exposing (Msg)
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> Session -> ( Session, Cmd SessionMsg )
update msg session =
    todo ""
