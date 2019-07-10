module Data.User exposing (User, authorizedUser, getToken, getUserInfo, guest, isLoggedIn)

import Data.AccessToken exposing (AccessToken)
import Data.UserInfo exposing (UserInfo)
import RemoteData exposing (RemoteData(..), WebData)


type User
    = Guest
    | AuthenticatedUser
        { token : AccessToken
        , userInfo : WebData UserInfo
        }


getToken : User -> Maybe AccessToken
getToken user =
    case user of
        Guest ->
            Nothing

        AuthenticatedUser { token } ->
            Just token


getUserInfo : User -> WebData UserInfo
getUserInfo user =
    case user of
        Guest ->
            NotAsked

        AuthenticatedUser { userInfo } ->
            userInfo


authorizedUser : AccessToken -> WebData UserInfo -> User
authorizedUser token userInfo =
    AuthenticatedUser
        { token = token
        , userInfo = userInfo
        }


guest : User
guest =
    Guest


isLoggedIn : User -> Bool
isLoggedIn user =
    case user of
        Guest ->
            False

        AuthenticatedUser _ ->
            True
