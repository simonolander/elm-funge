module Page.Execution.Subscriptions exposing (subscriptions)

import Browser.Events
import Maybe.Extra
import Page.Execution.Model exposing (ExecutionState(..), Model)
import Page.Execution.Msg exposing (Msg(..))
import Time


subscriptions : Model -> Sub Msg
subscriptions model =
    if Maybe.Extra.isJust model.execution then
        case model.state of
            Paused ->
                Sub.none

            Running ->
                Time.every 250 (always Tick)

            FastForwarding ->
                Browser.Events.onAnimationFrame (always Tick)

    else
        Sub.none
