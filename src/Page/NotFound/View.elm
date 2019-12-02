module Page.NotFound.View exposing (view)

import Data.Session exposing (Session)
import Page.Msg exposing (Msg)
import Page.NotFound.Model exposing (Model)
import Url
import View.Header
import View.NotFound
import View.Scewn


view : Session -> Model -> ( String, Msg )
view session model =
    let
        content =
            View.Scewn.layout
                { south = Nothing
                , center =
                    Just <|
                        View.NotFound.view
                            { noun = "page"
                            , id = Url.toString session.url
                            }
                , east = Nothing
                , west = Nothing
                , north = Just <| View.Header.view session
                , modal = Nothing
                }
    in
    ( "Not Found", content )
