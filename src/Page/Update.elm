module Page.Update exposing (update)

import Data.Session exposing (Session)
import Page.Blueprints.Update
import Page.Model as PageModel exposing (PageModel)
import Page.PageMsg exposing (..)


update : InternalMsg -> ( Session, PageModel ) -> ( ( Session, PageModel ), Cmd PageMsg )
update internalMsg ( session, pageModel ) =
    case ( internalMsg, pageModel ) of
        ( Blueprints msg, PageModel.Blueprints model ) ->
            Page.Blueprints.Update.update session msg model
                |> Tuple.mapFirst (Tuple.mapSecond PageModel.Blueprints)

        _ ->
            Debug.todo "Illegal message model combination"
