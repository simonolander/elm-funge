module Data.Board exposing (Board, count, decoder, empty, encode, get, height, instructions, set, width, withBoardInstruction, withHeight, withWidth)

import Array exposing (Array)
import Data.BoardInstruction as BoardInstruction exposing (BoardInstruction)
import Data.Instruction as Instruction exposing (Instruction)
import Data.Position exposing (Position)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Board =
    Array (Array Instruction)


withSize : Int -> Int -> Board -> Board
withSize w h board =
    withInstructions (instructions board) (empty w h)


withWidth : Int -> Board -> Board
withWidth w board =
    withSize w (height board) board


withHeight : Int -> Board -> Board
withHeight h board =
    withSize (width board) h board


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


withBoardInstruction : BoardInstruction -> Board -> Board
withBoardInstruction boardInstruction board =
    set boardInstruction.position boardInstruction.instruction board


instructions : Board -> List BoardInstruction
instructions board =
    board
        |> Array.indexedMap
            (\y row ->
                row
                    |> Array.indexedMap
                        (\x instruction ->
                            { position =
                                { x = x
                                , y = y
                                }
                            , instruction = instruction
                            }
                        )
                    |> Array.toList
            )
        |> Array.toList
        |> List.concat


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


withInstructions : List BoardInstruction -> Board -> Board
withInstructions boardInstructions board =
    let
        setInstruction { position, instruction } =
            set position instruction
    in
    List.foldl setInstruction board boardInstructions



-- JSON


encode : Board -> Encode.Value
encode board =
    Encode.object
        [ ( "width", Encode.int (width board) )
        , ( "height", Encode.int (height board) )
        , ( "instructions"
          , board
                |> instructions
                |> List.filter (.instruction >> (/=) Instruction.NoOp)
                |> Encode.list BoardInstruction.encode
          )
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
                    Decode.fail "All rows must have the same length"

                ( _, 0 ) ->
                    Decode.fail "Board cannot be empty"

                ( Just 0, _ ) ->
                    Decode.fail "Board cannot be empty"

                _ ->
                    Decode.succeed board
    in
    Decode.field "width" Decode.int
        |> Decode.andThen
            (\decodedWidth ->
                Decode.field "height" Decode.int
                    |> Decode.andThen
                        (\decodedHeight ->
                            Decode.field "instructions" (Decode.list BoardInstruction.decoder)
                                |> Decode.andThen
                                    (\decodedBoardInstructions ->
                                        empty decodedWidth decodedHeight
                                            |> withInstructions decodedBoardInstructions
                                            |> verifyBoard
                                    )
                        )
            )
