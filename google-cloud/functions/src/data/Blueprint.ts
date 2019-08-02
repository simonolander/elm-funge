import {JsonDecoder} from "ts.data.json";
import * as Board from "./Board";
import * as InstructionTool from "./InstructionTool";
import * as IO from "./IO";

export interface Blueprint {
    readonly id: string;
    readonly index: number;
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

export const decoder: JsonDecoder.Decoder<Blueprint> = JsonDecoder.object({
    id: JsonDecoder.string,
    index: JsonDecoder.number,
    name: JsonDecoder.string,
    description: JsonDecoder.array(JsonDecoder.string, "description"),
    io: IO.decoder,
    initialBoard: Board.decoder,
    instructionTools: JsonDecoder.array(InstructionTool.decoder, "instructionTools"),
    authorId: JsonDecoder.string,
    createdTime: JsonDecoder.number,
    modifiedTime: JsonDecoder.number,
    version: JsonDecoder.number,
}, "Blueprint");
