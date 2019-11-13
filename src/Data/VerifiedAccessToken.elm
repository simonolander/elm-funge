module Data.VerifiedAccessToken exposing
    ( VerifiedAccessToken(..)
    , getAny
    , getInvalid
    , getValid
    , invalidate
    , isMissing
    , isUnverified
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


isUnverified : VerifiedAccessToken -> Bool
isUnverified verifiedAccessToken =
    case verifiedAccessToken of
        None ->
            False

        Unverified _ ->
            True

        Invalid _ ->
            False

        Valid _ ->
            False


{-| TODO Rename to Missing instead of None
-}
isMissing : VerifiedAccessToken -> Bool
isMissing verifiedAccessToken =
    case verifiedAccessToken of
        None ->
            True

        _ ->
            False


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


getInvalid : VerifiedAccessToken -> Maybe AccessToken
getInvalid verifiedAccessToken =
    case verifiedAccessToken of
        Invalid accessToken ->
            Just accessToken

        _ ->
            Nothing


map : (AccessToken -> a) -> VerifiedAccessToken -> Maybe a
map function =
    getAny >> Maybe.map function


invalidate : Updater VerifiedAccessToken
invalidate =
    map Invalid >> Maybe.withDefault None


validate : Updater VerifiedAccessToken
validate =
    map Valid >> Maybe.withDefault None
