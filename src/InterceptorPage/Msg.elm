module InterceptorPage.Msg exposing (Msg(..))

import InterceptorPage.AccessTokenExpired.Msg as AccessTokenExpired
import InterceptorPage.Conflict.Msg as Conflict
import InterceptorPage.UnexpectedUserInfo.Msg as UnexpectedUserInfo


type Msg
    = ConflictMsg Conflict.Msg
    | UnexpectedUserInfoMsg UnexpectedUserInfo.Msg
    | AccessTokenExpiredMsg AccessTokenExpired.Msg
