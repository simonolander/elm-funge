module Page.View exposing (view)

import Data.Session exposing (Session)
import Debug exposing (todo)
import Html exposing (Html)
import Page.Blueprints.View
import Page.Model exposing (PageModel(..))
import Page.PageMsg exposing (PageMsg(..))


view : Session -> PageModel -> ( String, Html PageMsg )
view session pageModel =
    Tuple.mapSecond (Html.map InternalMsg) <|
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
                Page.Blueprints.View.view session model

            Initialize model ->
                todo ""

            NotFound model ->
                todo ""
