module Page.Subscriptions exposing (subscriptions)

import Page.Execution.Subscriptions
import Page.Model exposing (Model(..))
import Page.Msg as Msg exposing (Msg, PageMsg(..))


subscriptions : Model -> Sub Msg
subscriptions pageModel =
    case pageModel of
        ExecutionModel model ->
            Page.Execution.Subscriptions.subscriptions model
                |> Sub.map (ExecutionMsg >> Msg.PageMsg)

        _ ->
            Sub.none
