import {JsonDecoder} from "ts.data.json";
import {Blueprint} from "./Blueprint";
import * as Board from "./Board";
import * as InstructionTool from "./InstructionTool";
import * as IO from "./IO";

export interface Level {
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
    readonly version: number;
}

export const decoder: JsonDecoder.Decoder<Level> = JsonDecoder.object(
    {
        id: JsonDecoder.string,
        index: JsonDecoder.number,
        campaignId: JsonDecoder.string,
        name: JsonDecoder.string,
        description: JsonDecoder.array(JsonDecoder.string, "description"),
        io: IO.decoder,
        initialBoard: Board.decoder,
        instructionTools: JsonDecoder.array(InstructionTool.decoder, "instructionTools"),
        authorId: JsonDecoder.string,
        createdTime: JsonDecoder.number,
        version: JsonDecoder.number,
    },
    "Level",
);

export function fromBlueprint(blueprint: Blueprint): Level {
    return {
        id: blueprint.id,
        index: blueprint.index,
        campaignId: "blueprints",
        name: blueprint.name,
        description: blueprint.description,
        io: blueprint.io,
        initialBoard: blueprint.initialBoard,
        instructionTools: blueprint.instructionTools,
        authorId: blueprint.authorId,
        createdTime: Date.now(),
        version: 2,
    };
}
