import {JsonDecoder} from "ts.data.json";
import * as Board from "../Board";
import * as InstructionTool from "../InstructionTool";
import * as IO from "../IO";
import {Level} from "../Level";

export type LevelDto = V1;

interface V1 {
    readonly version: 1;
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
}

const versions = {
    v1: {
        encode(level: Level): LevelDto {
            return {
                version: 1,
                id: level.id,
                index: level.index,
                campaignId: level.campaignId,
                name: level.name,
                description: level.description,
                io: level.io,
                initialBoard: level.initialBoard,
                instructionTools: level.instructionTools,
                authorId: level.authorId,
                createdTime: level.createdTime,
            };
        },
        decoder: JsonDecoder.object({
            version: JsonDecoder.isExactly(1),
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
        }, "Level v1")
            .map(v1 => ({
                    id: v1.id,
                    index: v1.index,
                    campaignId: v1.campaignId,
                    name: v1.name,
                    description: v1.description,
                    io: v1.io,
                    initialBoard: v1.initialBoard,
                    instructionTools: v1.instructionTools,
                    authorId: v1.authorId,
                    createdTime: v1.createdTime,
                }),
            ),
    },
};

export function encode(level: Level): LevelDto {
    return versions.v1.encode(level);
}

export const decoder: JsonDecoder.Decoder<Level> = JsonDecoder.oneOf([versions.v1.decoder], "Level");
