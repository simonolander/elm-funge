import {JsonDecoder} from "ts.data.json";
import * as Board from "./Board";
import * as Integer from "./Integer";
import * as Score from "./Score";

export interface Solution {
    readonly version: number;
    readonly id: string;
    readonly levelId: string;
    readonly score: Score.Score;
    readonly board: Board.Board;
    readonly authorId: string;
}

export const decoder: JsonDecoder.Decoder<Solution> = JsonDecoder.object({
    version: Integer.nonNegativeDecoder,
    id: JsonDecoder.string,
    levelId: JsonDecoder.string,
    score: Score.decoder,
    board: Board.decoder,
    authorId: JsonDecoder.string,
}, "Solution");

decoder.decode = decoder.decode.bind(decoder);

export function isSame(a: Solution, b: Solution): boolean {
    if (a.levelId !== b.levelId) {
        return false;
    }
    return Board.equals(a.board, b.board);
}
