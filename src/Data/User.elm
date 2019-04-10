module Data.User exposing (User, authorizedUser, getToken, guest)

import Data.AuthorizationToken exposing (AuthorizationToken)


type User
    = Guest
    | AuthenticatedUser
        { token : AuthorizationToken
        }


getToken : User -> Maybe AuthorizationToken
getToken user =
    case user of
        Guest ->
            Nothing

        AuthenticatedUser { token } ->
            Just token


authorizedUser : AuthorizationToken -> User
authorizedUser token =
    AuthenticatedUser
        { token = token
        }


guest : User
guest =
    Guest
