module Data.Session exposing (Session)

import Browser.Navigation exposing (Key)
import Data.User exposing (User)


type alias Session =
    { key : Key
    , user : User
    }
