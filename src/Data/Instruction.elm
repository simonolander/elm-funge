module Data.Instruction exposing (Instruction(..), decoder, encode)

import Data.Direction as Direction exposing (Direction)
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, succeed)
import Json.Encode exposing (Value, int, object, string)


type Instruction
    = NoOp
    | ChangeDirection Direction
    | PushToStack Int
    | PopFromStack
    | JumpForward
    | Duplicate
    | Swap
    | Negate
    | Abs
    | Not
    | Increment
    | Decrement
    | Add
    | Subtract
    | Multiply
    | Divide
    | Equals
    | CompareLessThan
    | And
    | Or
    | XOr
    | Read
    | Print
    | Branch Direction Direction
    | Terminate
    | SendToBottom
    | Exception String



-- JSON


encode : Instruction -> Value
encode instruction =
    case instruction of
        NoOp ->
            object
                [ ( "tag", string "NoOp" ) ]

        ChangeDirection direction ->
            object
                [ ( "tag", string "ChangeDirection" )
                , ( "direction", Direction.encode direction )
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
                , ( "trueDirection", Direction.encode trueDirection )
                , ( "falseDirection", Direction.encode falseDirection )
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


decoder : Decoder Instruction
decoder =
    let
        tagToDecoder tag =
            case tag of
                "NoOp" ->
                    succeed NoOp

                "ChangeDirection" ->
                    field "direction" Direction.decoder
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
                    field "trueDirection" Direction.decoder
                        |> andThen
                            (\trueDirection ->
                                field "falseDirection" Direction.decoder
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
