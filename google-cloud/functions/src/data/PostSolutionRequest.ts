import {JsonDecoder} from "ts.data.json";
import * as Score from "./Score";
import * as Board from "./Board";

export interface PostSolutionRequest {
    readonly id: string,
    readonly levelId: string,
    readonly score: Score.Score,
    readonly board: Board.Board
}


export const decoder: JsonDecoder.Decoder<PostSolutionRequest> = JsonDecoder.object({
    id: JsonDecoder.string,
    levelId: JsonDecoder.string,
    score: Score.decoder,
    board: Board.decoder
}, "PostSolutionRequest");
