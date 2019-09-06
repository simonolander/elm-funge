import {Score} from "./Score";

export interface HighScore {
    readonly levelId: string;
    readonly numberOfSteps: Map<number, number>;
    readonly numberOfInstructions: Map<number, number>;
}

export function fromScores(levelId: string, scores: Score[]): HighScore {
    const highScore = {
        levelId,
        numberOfSteps: new Map(),
        numberOfInstructions: new Map(),
    };

    for (const score of scores) {
        const numberOfSteps = highScore.numberOfSteps.get(score.numberOfSteps);
        highScore.numberOfSteps.set(score.numberOfSteps, numberOfSteps === undefined ? 1 : numberOfSteps + 1);
        const numberOfInstructions = highScore.numberOfInstructions.get(score.numberOfInstructions);
        highScore.numberOfInstructions.set(score.numberOfInstructions, numberOfInstructions === undefined ? 1 : numberOfInstructions + 1);
    }

    return highScore;
}
