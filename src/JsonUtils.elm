module JsonUtils exposing
    ( boardDecoder
    , directionDecoder
    , encodeBoard
    , encodeDirection
    , encodeInstruction
    , encodeJumpLocation
    , instructionDecoder
    , jumpLocationDecoder
    )

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

        Jump jumpLocation ->
            object
                [ ( "tag", string "Jump" )
                , ( "jumpLocation", encodeJumpLocation jumpLocation )
                ]

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

                "Jump" ->
                    field "jumpLocation" jumpLocationDecoder
                        |> Decode.map Jump

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


encodeJumpLocation : JumpLocation -> Value
encodeJumpLocation jumpLocation =
    case jumpLocation of
        Forward ->
            string "Forward"


jumpLocationDecoder : Decoder JumpLocation
jumpLocationDecoder =
    let
        stringToJumpLocation stringValue =
            case stringValue of
                "Forward" ->
                    succeed Forward

                _ ->
                    fail ("'" ++ stringValue ++ "' could not be mapped to a JumpLocaction")
    in
    Decode.string
        |> andThen stringToJumpLocation


encodeBoard : Board -> Value
encodeBoard =
    array (array encodeInstruction)


boardDecoder : Decoder Board
boardDecoder =
    Decode.array (Decode.array instructionDecoder)
