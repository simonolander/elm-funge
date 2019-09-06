import * as Board from "./Board";

export interface Draft {
    id: string;
    levelId: string;
    board: Board.Board;
    authorId: string;
    createdTime: number;
    modifiedTime: number;
}
