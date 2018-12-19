module BoardUtils exposing
    ( count
    , empty
    , get
    , height
    , set
    , width
    )

import Array exposing (Array)
import List
import Model exposing (..)


empty : Int -> Int -> Board
empty boardWidth boardHeight =
    Array.repeat boardWidth NoOp
        |> Array.repeat boardHeight


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


width : Board -> Int
width board =
    Array.get 0 board
        |> Maybe.map Array.length
        |> Maybe.withDefault 0


height : Board -> Int
height board =
    Array.length board


count : (Instruction -> Bool) -> Board -> Int
count predicate board =
    board
        |> Array.map (\row -> row |> Array.filter predicate |> Array.length)
        |> Array.toList
        |> List.sum
