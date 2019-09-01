module View.NotFound exposing (view)

import Element exposing (..)
import Element.Font as Font
import View.Constant as Constant
import View.Info


view : { noun : String, id : String } -> Element msg
view { noun, id } =
    View.Info.view
        { title = "Resource not found"
        , icon =
            { src = Constant.icons.exceptionOrange
            , description = "Alert icon"
            }
        , elements =
            [ paragraph [ Font.center ]
                [ text "Could not find "
                , text noun
                , text " "
                , text id
                ]
            ]
        }
