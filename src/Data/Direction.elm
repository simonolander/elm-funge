module Data.Direction exposing (Direction(..), decoder, encode)

import Json.Decode as Decode exposing (Decoder, andThen, fail, succeed)
import Json.Encode exposing (Value, string)


type Direction
    = Left
    | Up
    | Right
    | Down



-- JSON


encode : Direction -> Value
encode direction =
    case direction of
        Left ->
            string "Left"

        Up ->
            string "Up"

        Right ->
            string "Right"

        Down ->
            string "Down"


decoder : Decoder Direction
decoder =
    let
        stringToDirection stringValue =
            case stringValue of
                "Left" ->
                    succeed Left

                "Up" ->
                    succeed Up

                "Right" ->
                    succeed Right

                "Down" ->
                    succeed Down

                _ ->
                    fail ("'" ++ stringValue ++ "' could not be mapped to a Direction")
    in
    Decode.string
        |> andThen stringToDirection
