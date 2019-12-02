module View.Box exposing (link, nonInteractive, simpleError, simpleInteractive, simpleLoading, simpleNonInteractive)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Route
import View.Constant exposing (color)


gray : Color
gray =
    rgb 0.2 0.2 0.2


nonInteractive : Element msg -> Element msg
nonInteractive element =
    el
        [ Border.color gray
        , Border.width 3
        , padding 10
        , width fill
        ]
        element


interactive : Element msg -> Element msg
interactive element =
    el
        [ width fill
        , Border.width 4
        , Border.color (rgb 1 1 1)
        , padding 10
        , mouseOver [ Background.color (rgba 1 1 1 0.5) ]
        , Background.color (rgb 0 0 0)
        , Font.color (rgb 1 1 1)
        ]
        element


simpleLoading : String -> Element msg
simpleLoading message =
    paragraph
        [ color.font.subtle
        , Font.center
        ]
        [ image
            [ width (px 20)
            , alignRight
            ]
            { src = "assets/spinner.svg"
            , description = ""
            }
        , text message
        ]
        |> nonInteractive


simpleNonInteractive : String -> Element msg
simpleNonInteractive message =
    paragraph
        [ color.font.subtle
        , Font.center
        ]
        [ text message
        ]
        |> nonInteractive


simpleError : String -> Element msg
simpleError message =
    paragraph
        [ color.font.error
        , Font.center
        ]
        [ text message ]
        |> nonInteractive


simpleInteractive message =
    interactive (paragraph [ Font.center, width fill ] [ text message ])


link : String -> Route.Route -> Element msg
link message route =
    Route.link
        [ width fill ]
        (simpleInteractive message)
        route
