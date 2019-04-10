module Data.Session exposing (Session, getToken)

import Browser.Navigation exposing (Key)
import Data.AuthorizationToken exposing (AuthorizationToken)
import Data.User as User exposing (User)


type alias Session =
    { key : Key
    , user : User
    }


getToken : Session -> Maybe AuthorizationToken
getToken =
    .user >> User.getToken
