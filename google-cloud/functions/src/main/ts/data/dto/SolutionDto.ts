import {JsonDecoder} from "ts.data.json";
import * as Board from "../Board";
import * as Score from "../Score";
import {Solution} from "../Solution";

export type SolutionDto =
    V1;

interface V1 {
    readonly version: 1;
    readonly id: string;
    readonly levelId: string;
    readonly score: Score.Score;
    readonly board: Board.Board;
    readonly authorId: string;
}

const versions = {
    v1: {
        encode(solution: Solution): V1 {
            return {
                version: 1,
                id: solution.id,
                levelId: solution.levelId,
                score: solution.score,
                board: solution.board,
                authorId: solution.authorId,
            };
        },
        decoder: JsonDecoder.object({
            version: JsonDecoder.isExactly(1),
            id: JsonDecoder.string,
            levelId: JsonDecoder.string,
            score: Score.decoder,
            board: Board.decoder,
            authorId: JsonDecoder.string,
        }, "Solution v1").map(v1 => ({
            id: v1.id,
            levelId: v1.levelId,
            score: v1.score,
            board: v1.board,
            authorId: v1.authorId,
        })),
    },
};

export function encode(solution: Solution): SolutionDto {
    return versions.v1.encode(solution);
}

export const decoder: JsonDecoder.Decoder<Solution> =
    JsonDecoder.oneOf([versions.v1.decoder], "Solution");
