module InterceptorPage.Update exposing (update)

import Data.Session exposing (Session)
import InterceptorPage.Conflict.Update as Conflict
import InterceptorPage.Initialize.Update as Initialize
import InterceptorPage.Msg exposing (Msg(..))
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> Session -> ( Session, Cmd SessionMsg )
update interceptionMsg session =
    case interceptionMsg of
        ConflictMsg msg ->
            Conflict.update msg session

        InitializeMsg msg ->
            Initialize.update msg session
