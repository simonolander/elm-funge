import {JsonDecoder} from "ts.data.json";
import * as Board from "../Board";
import {Draft} from "../Draft";

export type DraftDto = V1;

interface V1 {
    version: 1;
    id: string;
    levelId: string;
    board: Board.Board;
    authorId: string;
    createdTime: number;
    modifiedTime: number;
}

const versions = {
    v1: {
        encode(draft: Draft): V1 {
            return {
                version: 1,
                id: draft.id,
                levelId: draft.levelId,
                board: draft.board,
                authorId: draft.authorId,
                createdTime: draft.createdTime,
                modifiedTime: draft.modifiedTime,
            };
        },
        decoder: JsonDecoder.object({
            version: JsonDecoder.isExactly(1),
            id: JsonDecoder.string,
            levelId: JsonDecoder.string,
            board: Board.decoder,
            authorId: JsonDecoder.string,
            createdTime: JsonDecoder.number,
            modifiedTime: JsonDecoder.number,
        }, "Draft v1").map(v1 => ({
            id: v1.id,
            levelId: v1.levelId,
            board: v1.board,
            authorId: v1.authorId,
            createdTime: v1.createdTime,
            modifiedTime: v1.modifiedTime,
        })),
    },
};

export function encode(draft: Draft): DraftDto {
    return versions.v1.encode(draft);
}

export const decoder: JsonDecoder.Decoder<Draft> =
    JsonDecoder.oneOf([versions.v1.decoder], "Draft");
