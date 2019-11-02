module Page.Home.View exposing (view)

import ApplicationName exposing (applicationName)
import Browser exposing (Document)
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Page.Home.Model exposing (Model)
import Route
import Version exposing (version)
import View.Box as Box
import View.Constant exposing (size)
import View.Header
import View.Layout
import View.Scewn
import ViewComponents


view : Session -> Model -> Document msg
view session _ =
    let
        titleView =
            text applicationName
                |> el
                    [ centerX
                    , size.font.page.title
                    , padding 20
                    ]

        link text route =
            Route.link
                [ width fill ]
                (ViewComponents.textButton [] Nothing text)
                route

        header =
            View.Header.view session

        main =
            column
                [ padding 60
                , spacing 20
                , centerX
                , width (maximum 1000 fill)
                ]
                [ titleView
                , link "Campaigns" Route.Campaigns

                --                , link "Blueprints" (Route.Blueprints Nothing)
                , link "Credits" Route.Credits
                , Element.link [ width fill ]
                    { url = "https://github.com/simonolander/elm-funge/blob/master/documentation/docs.md"
                    , label = Box.simpleInteractive "Documentation"
                    }
                ]

        footer =
            row
                [ width fill
                ]
                [ Element.link
                    [ padding 20
                    , alignRight
                    , Font.color (rgb 0.25 0.25 0.25)
                    , mouseOver
                        [ Font.color (rgb 0.25 0.25 0.5)
                        ]
                    ]
                    { url = "https://github.com/simonolander/elm-funge"
                    , label = text version
                    }
                ]

        body =
            View.Scewn.view
                { north = Just header
                , center = Just main
                , west = Nothing
                , east = Nothing
                , south = Just footer
                , modal = Nothing
                }
                |> View.Layout.layout
                |> List.singleton
    in
    { title = "Home"
    , body = body
    }
