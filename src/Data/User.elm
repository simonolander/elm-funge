module Data.User exposing (User, authorizedUser, getToken, guest, isLoggedIn)

import Data.AccessToken exposing (AccessToken)


type User
    = Guest
    | AuthenticatedUser
        { token : AccessToken
        }


getToken : User -> Maybe AccessToken
getToken user =
    case user of
        Guest ->
            Nothing

        AuthenticatedUser { token } ->
            Just token


authorizedUser : AccessToken -> User
authorizedUser token =
    AuthenticatedUser
        { token = token
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
