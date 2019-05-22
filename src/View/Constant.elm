module View.Constant exposing (color)

import Element exposing (rgb)


color =
    { background =
        { black = rgb 0 0 0
        , selected = rgb 0.25 0.25 0.25
        , hovering = rgb 0.5 0.5 0.5
        }
    , font =
        { default = rgb 1 1 1
        , subtle = rgb 0.5 0.5 0.5
        , error = rgb 1 0.51 0.35
        }
    }
