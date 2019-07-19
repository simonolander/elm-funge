module Data.User exposing (User, authorizedUser, getToken, getUserInfo, guest, isLoggedIn, isOnline, withOnline, withUserInfo, withUserInfoWebData)

import Data.AccessToken exposing (AccessToken)
import Data.UserInfo exposing (UserInfo)
import RemoteData exposing (RemoteData(..), WebData)


type User
    = Guest
    | AuthenticatedUser
        { token : AccessToken
        , userInfo : WebData UserInfo
        , online : Bool
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
        , online = False
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


isOnline : User -> Bool
isOnline user =
    case user of
        Guest ->
            False

        AuthenticatedUser { online } ->
            online


withUserInfo : UserInfo -> User -> User
withUserInfo =
    Success >> withUserInfoWebData


withUserInfoWebData : WebData UserInfo -> User -> User
withUserInfoWebData webData user =
    case user of
        Guest ->
            Guest

        AuthenticatedUser record ->
            AuthenticatedUser { record | userInfo = webData }


withOnline : Bool -> User -> User
withOnline online user =
    case user of
        Guest ->
            Guest

        AuthenticatedUser record ->
            AuthenticatedUser { record | online = online }
