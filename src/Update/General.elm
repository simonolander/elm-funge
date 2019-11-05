module Update.General exposing (gotGetError, gotSaveError)

import Data.GetError as GetError exposing (GetError)
import Data.SaveError as SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Update.SessionMsg exposing (SessionMsg)


gotSaveError : SaveError -> Session -> ( Session, Cmd SessionMsg )
gotSaveError saveError session =
    case saveError of
        SaveError.InvalidAccessToken _ ->
            ( Session.updateAccessToken VerifiedAccessToken.invalidate session
            , SaveError.consoleError saveError
            )

        _ ->
            ( session, SaveError.consoleError saveError )


gotGetError : GetError -> Session -> ( Session, Cmd SessionMsg )
gotGetError saveError session =
    case saveError of
        GetError.InvalidAccessToken _ ->
            ( Session.updateAccessToken VerifiedAccessToken.invalidate session
            , GetError.consoleError saveError
            )

        _ ->
            ( session, GetError.consoleError saveError )
