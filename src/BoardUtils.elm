module BoardUtils exposing (empty, get, set)

import Array exposing (Array)
import Model exposing (..)


empty : Int -> Int -> Board
empty width height =
    Array.repeat width NoOp
        |> Array.repeat height


get : Position -> Board -> Maybe Instruction
get { x, y } board =
    Array.get y board
        |> Maybe.andThen (Array.get x)


set : Position -> Instruction -> Board -> Board
set { x, y } instruction board =
    case Array.get y board of
        Just row ->
            Array.set y (Array.set x instruction row) board

        Nothing ->
            board
