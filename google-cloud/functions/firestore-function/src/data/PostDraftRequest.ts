import {JsonDecoder} from "ts.data.json";
import * as Board from "./Board";

export interface PostDraftRequest {
    id: string,
    levelId: string,
    board: Board.Board
}

export const decoder: JsonDecoder.Decoder<PostDraftRequest> = JsonDecoder.object({
    id: JsonDecoder.string,
    levelId: JsonDecoder.string,
    board: Board.decoder
}, "PostDraftRequest");
