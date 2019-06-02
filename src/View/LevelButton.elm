module View.LevelButton exposing (Parameters, default, internal, loading, view)

import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import View.Constant exposing (color)


type alias Parameters msg =
    { attributes : List (Attribute msg)
    , onPress : Maybe msg
    , selected : Bool
    , marked : Bool
    }


default : Parameters msg
default =
    { attributes = []
    , onPress = Nothing
    , selected = False
    , marked = False
    }


loading : LevelId -> Element msg
loading levelId =
    column
        [ padding 20
        , Border.width 3
        , Border.color color.font.subtle
        , width (px 256)
        , spaceEvenly
        , height (px 181)
        ]
        [ el [ centerX ]
            (image
                [ width (px 30)
                ]
                { src = "assets/spinner.svg"
                , description = ""
                }
            )
        , el [ centerX ]
            (paragraph
                [ Font.color
                    (rgb 0.2 0.2 0.2)
                ]
                [ text levelId ]
            )
        ]


view : Parameters msg -> Level -> Element msg
view parameters level =
    internal parameters level.name level.id


internal : Parameters msg -> String -> String -> Element msg
internal parameters title subtitle =
    Input.button
        (if parameters.marked then
            htmlAttribute (Html.Attributes.class "solved") :: parameters.attributes

         else
            parameters.attributes
        )
        { onPress = parameters.onPress
        , label =
            column
                [ padding 20
                , Border.width 3
                , width (px 256)
                , spaceEvenly
                , height (px 181)
                , mouseOver
                    [ Background.color (rgba 1 1 1 0.5)
                    ]
                , Background.color
                    (if parameters.selected then
                        rgba 1 1 1 0.4

                     else
                        rgba 0 0 0 0
                    )
                ]
                [ el [ centerX, Font.center ] (paragraph [] [ text title ])
                , el [ centerX ]
                    (paragraph
                        [ Font.color
                            (rgb 0.2 0.2 0.2)
                        ]
                        [ text subtitle ]
                    )
                ]
        }
