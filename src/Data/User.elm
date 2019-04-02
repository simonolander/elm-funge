module Data.User exposing (User, authorizedUser, guest)

import Data.AuthorizationToken exposing (AuthorizationToken)


type User
    = Guest
    | AuthenticatedUser
        { token : AuthorizationToken
        }


authorizedUser : AuthorizationToken -> User
authorizedUser token =
    AuthenticatedUser
        { token = token
        }


guest : User
guest =
    Guest
