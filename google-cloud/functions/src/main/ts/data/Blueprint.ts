import * as Board from "./Board";
import * as InstructionTool from "./InstructionTool";
import * as Suite from "./Suite";

export interface Blueprint {
    readonly id: string;
    readonly name: string;
    readonly description: string[];
    readonly suites: Suite.Suite[];
    readonly initialBoard: Board.Board;
    readonly instructionTools: InstructionTool.InstructionTool[];
    readonly authorId: string;
    readonly createdTime: number;
    readonly modifiedTime: number;
}
