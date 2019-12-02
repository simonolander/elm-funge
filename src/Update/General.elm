module Update.General exposing (gotGetError, gotSaveError)

import Data.CmdUpdater exposing (CmdUpdater)
import Data.GetError as GetError exposing (GetError)
import Data.SaveError as SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken


gotSaveError : SaveError -> CmdUpdater Session msg
gotSaveError saveError session =
    case saveError of
        SaveError.InvalidAccessToken _ ->
            ( Session.updateAccessToken VerifiedAccessToken.invalidate session
            , SaveError.consoleError saveError
            )

        _ ->
            ( session, SaveError.consoleError saveError )


gotGetError : GetError -> CmdUpdater Session msg
gotGetError saveError session =
    case saveError of
        GetError.InvalidAccessToken _ ->
            ( Session.updateAccessToken VerifiedAccessToken.invalidate session
            , GetError.consoleError saveError
            )

        _ ->
            ( session, GetError.consoleError saveError )
