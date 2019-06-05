import * as BoardInstruction from "./BoardInstruction";
import {JsonDecoder} from "ts.data.json";
import * as Integer from "./Integer"

export interface Board {
    readonly width: number,
    readonly height: number,
    readonly instructions: Array<BoardInstruction.BoardInstruction>,
}

export const decoder: JsonDecoder.Decoder<Board> = JsonDecoder.object({
    width: Integer.nonNegativeDecoder,
    height: Integer.nonNegativeDecoder,
    instructions: JsonDecoder.array(BoardInstruction.decoder, "instructions"),
}, "Board");

export function equals(board1: Board, board2: Board): boolean {
    if (board1 === board2) {
        return true;
    }

    if (board1.width !== board2.width) {
        return false;
    }

    if (board1.height !== board2.height) {
        return false;
    }

    if (board1.instructions.length !== board2.instructions.length) {
        return false;
    }

    board1.instructions.sort(BoardInstruction.compareFn);
    board2.instructions.sort(BoardInstruction.compareFn);

    board1.instructions.every((v1, index) => {
        const v2 = board2.instructions[index];
        if (typeof v2 === "undefined") {
            return false;
        }
        return BoardInstruction.compareFn(v1, v2) === 0;
    });
    return true;
}
