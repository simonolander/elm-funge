module InterceptorPage.Update exposing (update)

import Data.Session exposing (Session)
import InterceptorPage.AccessTokenExpired.Update as AccessTokenExpired
import InterceptorPage.Conflict.Update as Conflict
import InterceptorPage.Msg exposing (Msg(..))
import InterceptorPage.UnexpectedUserInfo.Update as UnexpectedUserInfo
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> Session -> ( Session, Cmd SessionMsg )
update interceptionMsg session =
    case interceptionMsg of
        ConflictMsg msg ->
            Conflict.update msg session

        UnexpectedUserInfoMsg msg ->
            UnexpectedUserInfo.update msg session

        AccessTokenExpiredMsg msg ->
            AccessTokenExpired.update msg session
