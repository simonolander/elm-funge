module Data.InstructionTool exposing (InstructionTool(..), decoder, encode, getInstruction)

import Data.Direction exposing (Direction(..))
import Data.Instruction as Instruction exposing (Instruction(..))
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, succeed)
import Json.Encode exposing (Value, object, string)


type InstructionTool
    = JustInstruction Instruction
    | ChangeAnyDirection Direction
    | BranchAnyDirection Direction Direction
    | PushValueToStack String


getInstruction : InstructionTool -> Instruction
getInstruction instructionTool =
    case instructionTool of
        JustInstruction instruction ->
            instruction

        ChangeAnyDirection direction ->
            ChangeDirection direction

        BranchAnyDirection trueDirection falseDirection ->
            Branch trueDirection falseDirection

        PushValueToStack value ->
            value
                |> String.toInt
                |> Maybe.map PushToStack
                |> Maybe.withDefault (Exception (value ++ " is not a number"))



-- JSON


encode : InstructionTool -> Value
encode instructionTool =
    case instructionTool of
        JustInstruction instruction ->
            object
                [ ( "tag", string "JustInstruction" )
                , ( "instruction", Instruction.encode instruction )
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


decoder : Decoder InstructionTool
decoder =
    let
        tagToDecoder tag =
            case tag of
                "JustInstruction" ->
                    field "instruction" Instruction.decoder
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
