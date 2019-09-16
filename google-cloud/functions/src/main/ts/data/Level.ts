import {Blueprint} from "./Blueprint";
import * as Board from "./Board";
import * as InstructionTool from "./InstructionTool";
import * as Suite from "./Suite";

export interface Level {
    readonly id: string;
    readonly index: number;
    readonly campaignId: string;
    readonly name: string;
    readonly description: string[];
    readonly suites: Suite.Suite[];
    readonly initialBoard: Board.Board;
    readonly instructionTools: InstructionTool.InstructionTool[];
    readonly authorId: string;
    readonly createdTime: number;
}

export function fromBlueprint(blueprint: Blueprint): Level {
    return {
        id: blueprint.id,
        index: 0,
        campaignId: "blueprints",
        name: blueprint.name,
        description: blueprint.description,
        suites: [blueprint.io],
        initialBoard: blueprint.initialBoard,
        instructionTools: blueprint.instructionTools,
        authorId: blueprint.authorId,
        createdTime: Date.now(),
    };
}
