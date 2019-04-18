module View.LoadingScreen exposing (view)

import Element exposing (..)


view : String -> Element msg
view message =
    text message
        --        |> List.singleton
        --        |> paragraph []
        |> el [ scale 3, centerX, centerY ]
