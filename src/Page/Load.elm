module Page.Load exposing (load)

import Data.Session exposing (Session)
import Debug exposing (todo)
import Page.Home.Update
import Page.Model exposing (PageModel(..))
import Page.PageMsg exposing (PageMsg)


load : Session -> PageModel -> ( ( Session, PageModel ), Cmd PageMsg )
load session pageModel =
    case pageModel of
        Home model ->
            Page.Home.Update.load ( session, model )
                |> Tuple.mapFirst (Tuple.mapSecond Home)

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
