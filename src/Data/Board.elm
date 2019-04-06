module Data.Board exposing (Board, count, decoder, empty, encode, get, height, set, width)

import Array exposing (Array)
import Data.Instruction as Instruction exposing (Instruction)
import Data.Position exposing (Position)
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, succeed)
import Json.Encode exposing (Value, array, int, object)


type alias Board =
    Array (Array Instruction)


empty : Int -> Int -> Board
empty boardWidth boardHeight =
    Array.repeat boardWidth Instruction.NoOp
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



-- JSON


encode : Board -> Value
encode board =
    object
        [ ( "version", int 1 )
        , ( "board", array (array Instruction.encode) board )
        ]


decoder : Decoder Board
decoder =
    let
        verifyBoard board =
            let
                boardHeight =
                    Array.length board

                maybeWidth =
                    board
                        |> Array.toList
                        |> List.map Array.length
                        |> (\widths ->
                                case widths of
                                    [] ->
                                        Just 0

                                    rowWidth :: tail ->
                                        if List.all ((==) rowWidth) tail then
                                            Just rowWidth

                                        else
                                            Nothing
                           )
            in
            case ( maybeWidth, boardHeight ) of
                ( Nothing, _ ) ->
                    fail "All rows must have the same length"

                ( _, 0 ) ->
                    fail "Board cannot be empty"

                ( Just 0, _ ) ->
                    fail "Board cannot be empty"

                _ ->
                    succeed board

        boardDecoderV0 =
            Decode.array (Decode.array Instruction.decoder)
                |> andThen verifyBoard

        boardDecoderV1 =
            field "board" boardDecoderV0
    in
    Decode.maybe (field "version" Decode.int)
        |> andThen
            (\maybeVersion ->
                case maybeVersion of
                    Nothing ->
                        boardDecoderV0

                    Just 1 ->
                        boardDecoderV1

                    Just unknownVersion ->
                        fail ("Unknown version " ++ String.fromInt unknownVersion)
            )
