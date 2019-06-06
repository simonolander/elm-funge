import * as Score from "./Score";
import * as Board from "./Board";

export interface Solution {
    readonly id: string,
    readonly levelId: string,
    readonly score: Score.Score,
    readonly board: Board.Board,
    readonly authorId: string
}
