module Data.AuthorizationToken exposing (AuthorizationToken, fromString, toString)


type AuthorizationToken
    = AuthorizationToken String


toString : AuthorizationToken -> String
toString (AuthorizationToken token) =
    token


fromString : String -> AuthorizationToken
fromString =
    AuthorizationToken
