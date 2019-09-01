module View.Info exposing (view)

import Element exposing (..)
import Element.Font as Font


view :
    { title : String
    , icon : { src : String, description : String }
    , elements : List (Element msg)
    }
    -> Element msg
view { title, icon, elements } =
    column
        [ centerX
        , centerY
        , spacing 20
        , padding 40
        ]
        ([ image
            [ width (px 72)
            , centerX
            ]
            icon
         , paragraph
            [ Font.size 28
            , Font.center
            ]
            [ text title ]
         ]
            ++ elements
        )
