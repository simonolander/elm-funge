import {Score} from "./Score";

export interface HighScore {
    readonly levelId: string,
    readonly numberOfSteps: Map<number, number>,
    readonly numberOfInstructions: Map<number, number>,
}

export function fromScores(levelId: string, scores: Array<Score>): HighScore {
    const numberOfSteps = new Map;
    scores.forEach(score => {
        const current = numberOfSteps.get(score.numberOfSteps) || 0;
        numberOfSteps.set(score.numberOfSteps, current + 1);
    });

    const numberOfInstructions = new Map;
    scores.forEach(score => {
        const current = numberOfInstructions.get(score.numberOfInstructions) || 0;
        numberOfInstructions.set(score.numberOfInstructions, current + 1);
    });

    return {
        levelId,
        numberOfSteps,
        numberOfInstructions
    };
}
