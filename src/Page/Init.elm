module Page.Init exposing (init)

import Data.Session exposing (Session)
import Debug exposing (todo)
import Page.Model exposing (PageModel)
import Page.PageMsg exposing (PageMsg)
import Route
import Url exposing (Url)


init : Url -> Session -> ( ( Session, PageModel ), Cmd PageMsg )
init url session =
    case Route.fromUrl url of
        Nothing ->
            todo ""

        Just Route.Home ->
            todo ""

        Just (Route.Campaign campaignId maybeLevelId) ->
            todo ""

        Just Route.Campaigns ->
            todo ""

        Just (Route.EditDraft draftId) ->
            todo ""

        Just (Route.ExecuteDraft draftId) ->
            todo ""

        Just (Route.Blueprints maybeLevelId) ->
            todo ""

        Just (Route.Blueprint levelId) ->
            todo ""

        Just Route.Credits ->
            todo ""

        Just Route.NotFound ->
            todo ""
