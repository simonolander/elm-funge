import {JsonDecoder} from "ts.data.json";
import * as Board from "./Board";

export interface Draft {
    id: string,
    levelId: string,
    board: Board.Board,
    authorId: string,
    createdTime: number,
    modifiedTime: number
}

export const decoder: JsonDecoder.Decoder<Draft> = JsonDecoder.object({
    id: JsonDecoder.string,
    levelId: JsonDecoder.string,
    board: Board.decoder,
    authorId: JsonDecoder.string,
    createdTime: JsonDecoder.number,
    modifiedTime: JsonDecoder.number
}, "Draft");
