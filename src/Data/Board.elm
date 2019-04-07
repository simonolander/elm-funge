module Data.Board exposing (Board, count, decoder, empty, encode, get, height, set, width)

import Array exposing (Array)
import Data.Instruction as Instruction exposing (Instruction)
import Data.Position exposing (Position)
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, succeed)
import Json.Encode exposing (Value, array, int, list, object)


type alias Board =
    Array (Array Instruction)


type alias BoardInstruction =
    { x : Int
    , y : Int
    , instruction : Instruction
    }


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


instructions : Board -> List BoardInstruction
instructions board =
    board
        |> Array.indexedMap
            (\y row ->
                row
                    |> Array.indexedMap
                        (\x instruction ->
                            { x = x, y = y, instruction = instruction }
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
        setInstruction { x, y, instruction } =
            set { x = x, y = y } instruction
    in
    List.foldl setInstruction board boardInstructions



-- JSON


encodeBoardInstruction : BoardInstruction -> Value
encodeBoardInstruction boardInstruction =
    object
        [ ( "x", int boardInstruction.x )
        , ( "y", int boardInstruction.y )
        , ( "instruction", Instruction.encode boardInstruction.instruction )
        ]


boardInstructionDecoder : Decoder BoardInstruction
boardInstructionDecoder =
    Decode.field "x" Decode.int
        |> Decode.andThen
            (\x ->
                Decode.field "y" Decode.int
                    |> Decode.andThen
                        (\y ->
                            Decode.field "instruction" Instruction.decoder
                                |> andThen
                                    (\instruction ->
                                        Decode.succeed
                                            { x = x
                                            , y = y
                                            , instruction = instruction
                                            }
                                    )
                        )
            )


encode : Board -> Value
encode board =
    object
        [ ( "width", int (width board) )
        , ( "height", int (height board) )
        , ( "instructions"
          , board
                |> instructions
                |> list encodeBoardInstruction
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
                    fail "All rows must have the same length"

                ( _, 0 ) ->
                    fail "Board cannot be empty"

                ( Just 0, _ ) ->
                    fail "Board cannot be empty"

                _ ->
                    succeed board
    in
    Decode.field "width" Decode.int
        |> Decode.andThen
            (\decodedWidth ->
                Decode.field "height" Decode.int
                    |> Decode.andThen
                        (\decodedHeight ->
                            Decode.field "instructions" (Decode.list boardInstructionDecoder)
                                |> Decode.andThen
                                    (\decodedBoardInstructions ->
                                        empty decodedWidth decodedHeight
                                            |> withInstructions decodedBoardInstructions
                                            |> verifyBoard
                                    )
                        )
            )
