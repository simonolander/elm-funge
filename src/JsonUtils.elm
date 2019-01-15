module JsonUtils exposing
    ( boardDecoder
    , directionDecoder
    , encodeBoard
    , encodeDirection
    , encodeInstruction
    , instructionDecoder
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
                maybeWidthAndHeight =
                    board
                        |> Array.toList
                        |> List.map Array.length
                        |> (\lengths ->
                                case lengths of
                                    [] ->
                                        Just ( 0, 0 )

                                    length :: tail ->
                                        if List.all ((==) length) tail then
                                            Just ( length, List.length lengths )

                                        else
                                            Nothing
                           )
            in
            case maybeWidthAndHeight of
                Nothing ->
                    fail "All rows must have the same length"

                Just ( 0, 0 ) ->
                    fail "Board cannot be empty"

                Just ( _, _ ) ->
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
