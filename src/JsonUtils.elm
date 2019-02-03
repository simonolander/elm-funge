module JsonUtils exposing
    ( boardDecoder
    , directionDecoder
    , encodeBoard
    , encodeDirection
    , encodeInstruction
    , encodeLevel
    , fromString
    , instructionDecoder
    , levelDecoder
    , toString
    )

import Array
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, succeed)
import Json.Encode exposing (..)
import Model exposing (..)


encodeInstruction : Instruction -> Value
encodeInstruction instruction =
    case instruction of
        NoOp ->
            object
                [ ( "tag", string "NoOp" ) ]

        ChangeDirection direction ->
            object
                [ ( "tag", string "ChangeDirection" )
                , ( "direction", encodeDirection direction )
                ]

        PushToStack value ->
            object
                [ ( "tag", string "PushToStack" )
                , ( "value", int value )
                ]

        PopFromStack ->
            object
                [ ( "tag", string "PopFromStack" ) ]

        JumpForward ->
            object
                [ ( "tag", string "JumpForward" ) ]

        Duplicate ->
            object
                [ ( "tag", string "Duplicate" ) ]

        Swap ->
            object
                [ ( "tag", string "Swap" ) ]

        Negate ->
            object
                [ ( "tag", string "Negate" ) ]

        Abs ->
            object
                [ ( "tag", string "Abs" ) ]

        Not ->
            object
                [ ( "tag", string "Not" ) ]

        Increment ->
            object
                [ ( "tag", string "Increment" ) ]

        Decrement ->
            object
                [ ( "tag", string "Decrement" ) ]

        Add ->
            object
                [ ( "tag", string "Add" ) ]

        Subtract ->
            object
                [ ( "tag", string "Subtract" ) ]

        Multiply ->
            object
                [ ( "tag", string "Multiply" ) ]

        Divide ->
            object
                [ ( "tag", string "Divide" ) ]

        Equals ->
            object
                [ ( "tag", string "Equals" ) ]

        CompareLessThan ->
            object
                [ ( "tag", string "CompareLessThan" ) ]

        And ->
            object
                [ ( "tag", string "And" ) ]

        Or ->
            object
                [ ( "tag", string "Or" ) ]

        XOr ->
            object
                [ ( "tag", string "XOr" ) ]

        Read ->
            object
                [ ( "tag", string "Read" ) ]

        Print ->
            object
                [ ( "tag", string "Print" ) ]

        Branch trueDirection falseDirection ->
            object
                [ ( "tag", string "Branch" )
                , ( "trueDirection", encodeDirection trueDirection )
                , ( "falseDirection", encodeDirection falseDirection )
                ]

        Terminate ->
            object
                [ ( "tag", string "Terminate" ) ]

        SendToBottom ->
            object
                [ ( "tag", string "SendToBottom" ) ]

        Exception exceptionMessage ->
            object
                [ ( "tag", string "Exception" )
                , ( "exceptionMessage", string exceptionMessage )
                ]


instructionDecoder : Decoder Instruction
instructionDecoder =
    let
        tagToDecoder tag =
            case tag of
                "NoOp" ->
                    succeed NoOp

                "ChangeDirection" ->
                    field "direction" directionDecoder
                        |> Decode.map ChangeDirection

                "PushToStack" ->
                    field "value" Decode.int
                        |> Decode.map PushToStack

                "PopFromStack" ->
                    succeed PopFromStack

                "JumpForward" ->
                    succeed JumpForward

                -- Deprecated, use "JumpForward"
                "Jump" ->
                    succeed JumpForward

                "Duplicate" ->
                    succeed Duplicate

                "Swap" ->
                    succeed Swap

                "Negate" ->
                    succeed Negate

                "Abs" ->
                    succeed Abs

                "Not" ->
                    succeed Not

                "Increment" ->
                    succeed Increment

                "Decrement" ->
                    succeed Decrement

                "Add" ->
                    succeed Add

                "Subtract" ->
                    succeed Subtract

                "Multiply" ->
                    succeed Multiply

                "Divide" ->
                    succeed Divide

                "Equals" ->
                    succeed Equals

                "CompareLessThan" ->
                    succeed CompareLessThan

                "And" ->
                    succeed And

                "Or" ->
                    succeed Or

                "XOr" ->
                    succeed XOr

                "Read" ->
                    succeed Read

                "Print" ->
                    succeed Print

                "Branch" ->
                    field "trueDirection" directionDecoder
                        |> andThen
                            (\trueDirection ->
                                field "falseDirection" directionDecoder
                                    |> andThen
                                        (\falseDirection ->
                                            succeed (Branch trueDirection falseDirection)
                                        )
                            )

                "Terminate" ->
                    succeed Terminate

                "SendToBottom" ->
                    succeed SendToBottom

                "Exception" ->
                    field "exceptionMessage" Decode.string
                        |> Decode.map Exception

                _ ->
                    fail ("Unknown instruction tag: " ++ tag)
    in
    field "tag" Decode.string
        |> andThen tagToDecoder


encodeDirection : Direction -> Value
encodeDirection direction =
    case direction of
        Left ->
            string "Left"

        Up ->
            string "Up"

        Right ->
            string "Right"

        Down ->
            string "Down"


directionDecoder : Decoder Direction
directionDecoder =
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


encodeBoard : Board -> Value
encodeBoard board =
    object
        [ ( "version", int 1 )
        , ( "board", array (array encodeInstruction) board )
        ]


boardDecoder : Decoder Board
boardDecoder =
    let
        verifyBoard board =
            let
                height =
                    Array.length board

                maybeWidth =
                    board
                        |> Array.toList
                        |> List.map Array.length
                        |> (\widths ->
                                case widths of
                                    [] ->
                                        Just 0

                                    width :: tail ->
                                        if List.all ((==) width) tail then
                                            Just width

                                        else
                                            Nothing
                           )
            in
            case ( maybeWidth, height ) of
                ( Nothing, _ ) ->
                    fail "All rows must have the same length"

                ( _, 0 ) ->
                    fail "Board cannot be empty"

                ( Just 0, _ ) ->
                    fail "Board cannot be empty"

                _ ->
                    succeed board

        boardDecoderV0 =
            Decode.array (Decode.array instructionDecoder)
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


encodeInstructionTool : InstructionTool -> Value
encodeInstructionTool instructionTool =
    case instructionTool of
        JustInstruction instruction ->
            object
                [ ( "tag", string "JustInstruction" )
                , ( "instruction", encodeInstruction instruction )
                ]

        ChangeAnyDirection _ ->
            object
                [ ( "tag", string "ChangeAnyDirection" )
                ]

        BranchAnyDirection _ _ ->
            object
                [ ( "tag", string "BranchAnyDirection" )
                ]

        PushValueToStack _ ->
            object
                [ ( "tag", string "PushValueToStack" )
                ]


instructionToolDecoder : Decoder InstructionTool
instructionToolDecoder =
    let
        tagToDecoder tag =
            case tag of
                "JustInstruction" ->
                    field "instruction" instructionDecoder
                        |> Decode.map JustInstruction

                "ChangeAnyDirection" ->
                    succeed (ChangeAnyDirection Left)

                "BranchAnyDirection" ->
                    succeed (BranchAnyDirection Left Right)

                "PushValueToStack" ->
                    succeed (PushValueToStack "0")

                _ ->
                    fail ("Unknown instruction tool tag: " ++ tag)
    in
    field "tag" Decode.string
        |> andThen tagToDecoder


encodeIO : IO -> Value
encodeIO io =
    object
        [ ( "input", list int io.input )
        , ( "output", list int io.output )
        ]


ioDecoder : Decoder IO
ioDecoder =
    field "input" (Decode.list Decode.int)
        |> andThen
            (\input ->
                field "output" (Decode.list Decode.int)
                    |> andThen
                        (\output ->
                            succeed
                                { input = input
                                , output = output
                                }
                        )
            )


encodeLevel : Level -> Value
encodeLevel level =
    object
        [ ( "version", int 1 )
        , ( "id", string level.id )
        , ( "name", string level.name )
        , ( "description", list string level.description )
        , ( "io", encodeIO level.io )
        , ( "initialBoard", encodeBoard level.initialBoard )
        , ( "instructionTools", list encodeInstructionTool level.instructionTools )
        ]


levelDecoder : Decoder Level
levelDecoder =
    let
        levelDecoderV1 =
            field "id" Decode.string
                |> andThen
                    (\id ->
                        field "name" Decode.string
                            |> andThen
                                (\name ->
                                    field "description" (Decode.list Decode.string)
                                        |> andThen
                                            (\description ->
                                                field "io" ioDecoder
                                                    |> andThen
                                                        (\io ->
                                                            field "initialBoard" boardDecoder
                                                                |> andThen
                                                                    (\initialBoard ->
                                                                        field "instructionTools" (Decode.list instructionToolDecoder)
                                                                            |> andThen
                                                                                (\instructionTools ->
                                                                                    succeed
                                                                                        { id = id
                                                                                        , name = name
                                                                                        , description = description
                                                                                        , io = io
                                                                                        , initialBoard = initialBoard
                                                                                        , instructionTools = instructionTools
                                                                                        }
                                                                                )
                                                                    )
                                                        )
                                            )
                                )
                    )
    in
    field "version" Decode.int
        |> andThen
            (\version ->
                case version of
                    1 ->
                        levelDecoderV1

                    _ ->
                        fail
                            ("Unknown level decoder version: "
                                ++ String.fromInt version
                            )
            )


toString : Value -> String
toString =
    encode 2


fromString : Decoder a -> String -> Result Decode.Error a
fromString =
    Decode.decodeString
