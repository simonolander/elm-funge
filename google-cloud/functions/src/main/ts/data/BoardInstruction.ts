import {JsonDecoder} from "ts.data.json";
import * as Instruction from "./Instruction";
import * as Position from "./Position";

export interface BoardInstruction {
    readonly position: Position.Position;
    readonly instruction: Instruction.Instruction;
}

export const decoder: JsonDecoder.Decoder<BoardInstruction> = JsonDecoder.object({
    position: Position.decoder,
    instruction: Instruction.decoder,
}, "BoardInstruction");

export function compareFn(a: BoardInstruction, b: BoardInstruction) {
    const positionComparison = Position.compareFn(a.position, b.position);
    if (positionComparison !== 0) {
        return positionComparison;
    }

    return Instruction.compareFn(a.instruction, b.instruction);
}
