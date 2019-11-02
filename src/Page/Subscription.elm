module Page.Subscription exposing (subscriptions)

import Debug exposing (todo)
import Page.Model exposing (PageModel(..))
import Page.PageMsg exposing (PageMsg)


subscriptions : PageModel -> Sub PageMsg
subscriptions pageModel =
    case pageModel of
        Home model ->
            todo ""

        Campaign model ->
            todo ""

        Campaigns model ->
            todo ""

        Credits model ->
            todo ""

        Execution model ->
            todo ""

        Draft model ->
            todo ""

        Blueprint model ->
            todo ""

        Blueprints model ->
            todo ""

        Initialize model ->
            todo ""

        NotFound model ->
            todo ""
