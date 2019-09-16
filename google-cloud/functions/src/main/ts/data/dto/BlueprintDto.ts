import {JsonDecoder} from "ts.data.json";
import {Blueprint} from "../Blueprint";
import * as Board from "../Board";
import * as InstructionTool from "../InstructionTool";
import * as Suite from "../Suite";

export type BlueprintDto = V1;

interface V1 {
    readonly version: 1;
    readonly id: string;
    readonly name: string;
    readonly description: string[];
    readonly io: Suite.Suite;
    readonly initialBoard: Board.Board;
    readonly instructionTools: InstructionTool.InstructionTool[];
    readonly authorId: string;
    readonly createdTime: number;
    readonly modifiedTime: number;
}

const versions = {
    v1: {
        encode(blueprint: Blueprint): BlueprintDto {
            return {
                version: 1,
                id: blueprint.id,
                name: blueprint.name,
                description: blueprint.description,
                io: blueprint.io,
                initialBoard: blueprint.initialBoard,
                instructionTools: blueprint.instructionTools,
                authorId: blueprint.authorId,
                createdTime: blueprint.createdTime,
                modifiedTime: blueprint.modifiedTime,
            };
        },
        decoder: JsonDecoder.object({
            version: JsonDecoder.isExactly(1),
            id: JsonDecoder.string,
            name: JsonDecoder.string,
            description: JsonDecoder.array(JsonDecoder.string, "description"),
            io: Suite.decoder,
            initialBoard: Board.decoder,
            instructionTools: JsonDecoder.array(InstructionTool.decoder, "instructionTools"),
            authorId: JsonDecoder.string,
            createdTime: JsonDecoder.number,
            modifiedTime: JsonDecoder.number,
        }, "Blueprint v1")
            .map(v1 => ({
                    id: v1.id,
                    name: v1.name,
                    description: v1.description,
                    io: v1.io,
                    initialBoard: v1.initialBoard,
                    instructionTools: v1.instructionTools,
                    authorId: v1.authorId,
                    createdTime: v1.createdTime,
                    modifiedTime: v1.createdTime,
                }),
            ),
    },
};

export function encode(blueprint: Blueprint): BlueprintDto {
    return versions.v1.encode(blueprint);
}

export const decoder: JsonDecoder.Decoder<Blueprint> = JsonDecoder.oneOf([versions.v1.decoder], "Blueprint");
