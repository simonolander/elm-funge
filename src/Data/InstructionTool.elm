module Data.InstructionTool exposing (InstructionTool(..), all, decoder, encode, getInstruction)

import Data.Direction exposing (Direction(..))
import Data.Instruction as Instruction exposing (Instruction(..))
import Data.Int16 as Int16
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, succeed)
import Json.Encode exposing (Value, object, string)


type InstructionTool
    = JustInstruction Instruction
    | ChangeAnyDirection Direction
    | BranchAnyDirection Direction Direction
    | PushValueToStack String
    | Exception String


all : List InstructionTool
all =
    List.concat
        [ Instruction.allSimple
            |> List.map JustInstruction
        , [ ChangeAnyDirection Left
          , BranchAnyDirection Left Right
          , Exception ""
          ]
        ]


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
                |> Int16.fromString
                |> Maybe.map PushToStack
                |> Maybe.withDefault (Instruction.Exception (value ++ " is not a number"))

        Exception exceptionMessage ->
            Instruction.Exception exceptionMessage



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

        Exception _ ->
            object
                [ ( "tag", string "Exception" )
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

                "Exception" ->
                    succeed (Exception "")

                _ ->
                    fail ("Unknown instruction tool tag: " ++ tag)
    in
    field "tag" Decode.string
        |> andThen tagToDecoder
