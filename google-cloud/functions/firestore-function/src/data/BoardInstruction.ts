import * as Instruction from "./Instruction";
import {JsonDecoder} from "ts.data.json";
import * as Position from "./Position";

export interface BoardInstruction {
    readonly position: Position.Position,
    readonly instruction: Instruction.Instruction
}


export const decoder: JsonDecoder.Decoder<BoardInstruction> = JsonDecoder.object({
    position: Position.decoder,
    instruction: Instruction.decoder
}, "BoardInstruction");
