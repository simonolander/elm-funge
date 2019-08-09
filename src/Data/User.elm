module Data.User exposing (User, authorizedUser, getToken, getUserInfo, guest, withUserInfo)

import Data.AccessToken exposing (AccessToken)
import Data.UserInfo exposing (UserInfo)


type alias User =
    { accessToken : Maybe AccessToken
    , userInfo : Maybe UserInfo
    }


getToken : User -> Maybe AccessToken
getToken user =
    user.accessToken


getUserInfo : User -> Maybe UserInfo
getUserInfo user =
    user.userInfo


authorizedUser : AccessToken -> UserInfo -> User
authorizedUser accessToken userInfo =
    { accessToken = Just accessToken
    , userInfo = Just userInfo
    }


guest : User
guest =
    { accessToken = Nothing
    , userInfo = Nothing
    }


withAccessToken : Maybe AccessToken -> User -> User
withAccessToken accessToken user =
    { user | accessToken = accessToken }


withUserInfo : Maybe UserInfo -> User -> User
withUserInfo userInfo user =
    { user | userInfo = userInfo }
