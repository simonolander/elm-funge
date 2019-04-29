module View.Header exposing (header)

import Element exposing (..)


header session =
    row
        [ alignRight ]
        [ text "Logout" ]
