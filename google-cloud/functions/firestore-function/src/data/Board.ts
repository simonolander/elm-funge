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
    return true; // TODO
}
