import * as Board from "./Board";
import * as InstructionTool from "./InstructionTool";
import * as IO from "./IO";

export interface Blueprint {
    readonly id: string;
    readonly index: number;
    readonly campaignId: string;
    readonly name: string;
    readonly description: string[];
    readonly io: IO.IO;
    readonly initialBoard: Board.Board;
    readonly instructionTools: InstructionTool.InstructionTool[];
    readonly authorId: string;
    readonly createdTime: number;
    readonly modifiedTime: number;
    readonly version: number;
}
