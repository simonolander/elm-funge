module Data.AccessToken exposing (AccessToken, fromString, toString)


type AccessToken
    = AccessToken String


toString : AccessToken -> String
toString (AccessToken accessToken) =
    accessToken


fromString : String -> AccessToken
fromString =
    AccessToken
