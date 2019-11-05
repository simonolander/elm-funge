module Data.VerifiedAccessToken exposing
    ( VerifiedAccessToken(..)
    , getAny
    , getValid
    , invalidate
    , map
    , validate
    )

import Data.AccessToken exposing (AccessToken)
import Data.Updater exposing (Updater)


type VerifiedAccessToken
    = None
    | Unverified AccessToken
    | Invalid AccessToken
    | Valid AccessToken


getValid : VerifiedAccessToken -> Maybe AccessToken
getValid verifiedAccessToken =
    case verifiedAccessToken of
        None ->
            Nothing

        Unverified _ ->
            Nothing

        Invalid _ ->
            Nothing

        Valid accessToken ->
            Just accessToken


getAny : VerifiedAccessToken -> Maybe AccessToken
getAny verifiedAccessToken =
    case verifiedAccessToken of
        None ->
            Nothing

        Unverified accessToken ->
            Just accessToken

        Invalid accessToken ->
            Just accessToken

        Valid accessToken ->
            Just accessToken


map : (AccessToken -> a) -> VerifiedAccessToken -> Maybe a
map function =
    getAny >> Maybe.map function


invalidate : Updater VerifiedAccessToken
invalidate =
    map Invalid >> Maybe.withDefault None


validate : Updater VerifiedAccessToken
validate =
    map Valid >> Maybe.withDefault None
