module Data.User exposing (User, authorizedUser, getToken, getUserInfo, guest, withUserInfo)

import Data.AccessToken exposing (AccessToken)
import Data.UserInfo exposing (UserInfo)
import RemoteData exposing (RemoteData(..), WebData)


type alias User =
    { token : Maybe AccessToken
    , userInfo : Maybe UserInfo
    }


getToken : User -> Maybe AccessToken
getToken user =
    user.token


getUserInfo : User -> Maybe UserInfo
getUserInfo user =
    user.userInfo


authorizedUser : AccessToken -> UserInfo -> User
authorizedUser token userInfo =
    { token = Just token
    , userInfo = Just userInfo
    }


guest : User
guest =
    { token = Nothing
    , userInfo = Nothing
    }


withAccessToken : Maybe AccessToken -> User -> User
withAccessToken accessToken user =
    { user | token = accessToken }


withUserInfo : Maybe UserInfo -> User -> User
withUserInfo userInfo user =
    { user | userInfo = userInfo }
