module InterceptorPage.Conflict.Update exposing (update)

import Data.CmdUpdater exposing (CmdUpdater)
import Data.Session exposing (Session)
import InterceptorPage.Conflict.Msg exposing (Msg(..))
import Service.Blueprint.BlueprintService as BlueprintService
import Service.Draft.DraftService as DraftService
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> CmdUpdater Session SessionMsg
update msg session =
    case msg of
        ClickedKeepLocalDraft id ->
            DraftService.resolveManuallyKeepLocalDraft id session

        ClickedKeepServerDraft id ->
            DraftService.resolveManuallyKeepServerDraft id session

        ClickedKeepLocalBlueprint id ->
            BlueprintService.resolveManuallyKeepLocalBlueprint id session

        ClickedKeepServerBlueprint id ->
            BlueprintService.resolveManuallyKeepServerBlueprint id session
