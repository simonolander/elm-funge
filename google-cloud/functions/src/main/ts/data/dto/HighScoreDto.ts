import {HighScore} from "../HighScore";

export type HighScoreDto = V1;

interface V1 {
    readonly version: 1;
    readonly levelId: string;
    readonly numberOfSteps: Array<[number, number]>;
    readonly numberOfInstructions: Array<[number, number]>;
}

const versions = {
    v1: {
        encode(highScore: HighScore): V1 {
            return {
                version: 1,
                levelId: highScore.levelId,
                numberOfSteps: [...highScore.numberOfSteps.entries()],
                numberOfInstructions: [...highScore.numberOfInstructions.entries()],
            };
        },
    },
};

export function encode(highScore: HighScore): HighScoreDto {
    return versions.v1.encode(highScore);
}
