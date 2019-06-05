import {Score} from "./Score";

export interface HighScore {
    readonly levelId: string,
    readonly numberOfSteps: Map<number, number>,
    readonly numberOfInstructions: Map<number, number>,
}

export function fromScores(levelId: string, scores: Array<Score>): HighScore {
    const numberOfSteps = new Map(scores.map(score => [score.numberOfSteps, 0]));
    scores.forEach(score => numberOfSteps[score.numberOfSteps] += 1);

    const numberOfInstructions = new Map(scores.map(score => [score.numberOfInstructions, 0]));
    scores.forEach(score => numberOfInstructions[score.numberOfInstructions] += 1);

    return {
        levelId,
        numberOfSteps,
        numberOfInstructions
    };
}
