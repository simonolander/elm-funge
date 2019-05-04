module Data.BoardInstruction exposing (BoardInstruction, decoder, encode, withInstruction)

import Data.Instruction as Instruction exposing (Instruction)
import Data.Position as Position exposing (Position)
import Json.Decode as Decode
import Json.Encode as Encode


type alias BoardInstruction =
    { position : Position
    , instruction : Instruction
    }


withInstruction : Instruction -> BoardInstruction -> BoardInstruction
withInstruction instruction boardInstruction =
    { boardInstruction | instruction = instruction }



-- JSON


encode : BoardInstruction -> Encode.Value
encode boardInstruction =
    Encode.object
        [ ( "position", Position.encode boardInstruction.position )
        , ( "instruction", Instruction.encode boardInstruction.instruction )
        ]


decoder : Decode.Decoder BoardInstruction
decoder =
    Decode.field "position" Position.decoder
        |> Decode.andThen
            (\position ->
                Decode.field "instruction" Instruction.decoder
                    |> Decode.andThen
                        (\instruction ->
                            Decode.succeed
                                { position = position
                                , instruction = instruction
                                }
                        )
            )
