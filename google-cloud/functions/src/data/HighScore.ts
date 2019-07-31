import {Score} from "./Score";

export interface HighScore {
    readonly levelId: string,
    readonly numberOfSteps: Array<[number, number]>,
    readonly numberOfInstructions: Array<[number, number]>,
}

export function fromScores(levelId: string, scores: Array<Score>): HighScore {
    const numberOfSteps: {[s: number]: number} = {};
    scores.forEach(score => {
        numberOfSteps[score.numberOfSteps] = (numberOfSteps[score.numberOfSteps] || 0) + 1;
    });

    const numberOfInstructions: {[s: number]: number} = {};
    scores.forEach(score => {
        numberOfInstructions[score.numberOfInstructions] = (numberOfInstructions[score.numberOfInstructions] || 0) + 1;
    });

    return {
        levelId,
        numberOfSteps: Object.entries(numberOfSteps).map(([key, value]) => [parseInt(key), value]),
        numberOfInstructions: Object.entries(numberOfInstructions).map(([key, value]) => [parseInt(key), value])
    };
}
