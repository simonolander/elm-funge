import {JsonDecoder} from "ts.data.json";
import * as Board from "../Board";
import * as InstructionTool from "../InstructionTool";
import {Level} from "../Level";
import * as Suite from "../Suite";

export type LevelDto = V1 | V2;

interface V1 {
    readonly version: 1;
    readonly id: string;
    readonly index: number;
    readonly campaignId: string;
    readonly name: string;
    readonly description: string[];
    readonly io: Suite.Suite;
    readonly initialBoard: Board.Board;
    readonly instructionTools: InstructionTool.InstructionTool[];
    readonly authorId: string;
    readonly createdTime: number;
}

interface V2 {
    readonly version: 2;
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

const versions = {
    v1: {
        decoder: JsonDecoder.object({
            version: JsonDecoder.isExactly(1),
            id: JsonDecoder.string,
            index: JsonDecoder.number,
            campaignId: JsonDecoder.string,
            name: JsonDecoder.string,
            description: JsonDecoder.array(JsonDecoder.string, "description"),
            io: Suite.decoder,
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
                    suites: [v1.io],
                    initialBoard: v1.initialBoard,
                    instructionTools: v1.instructionTools,
                    authorId: v1.authorId,
                    createdTime: v1.createdTime,
                }),
            ),
    },
    v2: {
        encode(level: Level): LevelDto {
            return {
                version: 2,
                id: level.id,
                index: level.index,
                campaignId: level.campaignId,
                name: level.name,
                description: level.description,
                suites: level.suites,
                initialBoard: level.initialBoard,
                instructionTools: level.instructionTools,
                authorId: level.authorId,
                createdTime: level.createdTime,
            };
        },
        decoder: JsonDecoder.object({
            version: JsonDecoder.isExactly(2),
            id: JsonDecoder.string,
            index: JsonDecoder.number,
            campaignId: JsonDecoder.string,
            name: JsonDecoder.string,
            description: JsonDecoder.array(JsonDecoder.string, "description"),
            suites: JsonDecoder.array(Suite.decoder, "Suite[]"),
            initialBoard: Board.decoder,
            instructionTools: JsonDecoder.array(InstructionTool.decoder, "instructionTools"),
            authorId: JsonDecoder.string,
            createdTime: JsonDecoder.number,
        }, "Level v2")
            .map(v2 => ({
                    id: v2.id,
                    index: v2.index,
                    campaignId: v2.campaignId,
                    name: v2.name,
                    description: v2.description,
                    suites: v2.suites,
                    initialBoard: v2.initialBoard,
                    instructionTools: v2.instructionTools,
                    authorId: v2.authorId,
                    createdTime: v2.createdTime,
                }),
            ),
    },
};

export function encode(level: Level): LevelDto {
    return versions.v2.encode(level);
}

export const decoder: JsonDecoder.Decoder<Level> = JsonDecoder.oneOf(Object.values(versions).map(v => v.decoder), "Level");
