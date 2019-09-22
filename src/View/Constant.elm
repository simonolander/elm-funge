module View.Constant exposing (color, icons, size)

import Element exposing (rgb)
import Element.Font as Font


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
        , link = rgb 0.5 0.5 1
        , linkHover = rgb 0.75 0.75 1
        }
    }


size =
    { font =
        { card = { title = Font.size 24 }
        , section = { title = Font.size 28 }
        , page = { title = Font.size 42 }
        }
    }


icons =
    { exceptionOrange = "assets/exception-orange.svg"
    , circle =
        { green = "assets/misc/circle-green.svg"
        , red = "assets/misc/circle-red.svg"
        }
    , spinner = "assets/spinner.svg"
    , pause = "assets/execution-control-images/pause.svg"
    }
