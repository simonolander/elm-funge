module InterceptorPage.AccessTokenExpired.Update exposing (update)

import Data.CmdUpdater exposing (CmdUpdater)
import Data.Session exposing (Session)
import Data.VerifiedAccessToken exposing (VerifiedAccessToken(..))
import InterceptorPage.AccessTokenExpired.Msg exposing (Msg(..))
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> CmdUpdater Session SessionMsg
update msg session =
    case msg of
        ClickedContinueOffline ->
            ( { session | accessToken = None }, Cmd.none )
