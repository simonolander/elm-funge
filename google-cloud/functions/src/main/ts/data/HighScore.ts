import {Score} from "./Score";

export interface HighScore {
    readonly levelId: string;
    readonly numberOfSteps: Array<[number, number]>;
    readonly numberOfInstructions: Array<[number, number]>;
}

export function fromScores(levelId: string, scores: Score[]): HighScore {
    const numberOfSteps: {[s: number]: number} = {};
    scores.forEach(score => {
        const oldCount = typeof numberOfSteps[score.numberOfSteps] === "number"
            ? numberOfSteps[score.numberOfSteps]
            : 0;
        numberOfSteps[score.numberOfSteps] = oldCount + 1;
    });

    const numberOfInstructions: {[s: number]: number} = {};
    scores.forEach(score => {
        const oldCount = typeof numberOfInstructions[score.numberOfInstructions] === "number"
            ? numberOfInstructions[score.numberOfInstructions]
            : 0;
        numberOfInstructions[score.numberOfInstructions] = oldCount + 1;
    });

    return {
        levelId,
        numberOfSteps: Object.entries(numberOfSteps).map(([key, value]) => [parseInt(key), value]),
        numberOfInstructions: Object.entries(numberOfInstructions).map(([key, value]) => [parseInt(key), value]),
    };
}
