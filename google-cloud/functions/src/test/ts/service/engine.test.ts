import * as LevelDto from "../../../main/ts/data/dto/LevelDto";
import * as SolutionDto from "../../../main/ts/data/dto/SolutionDto";
import {Instruction} from "../../../main/ts/data/Instruction";
import {decodeOrThrow} from "../../../main/ts/misc/json";
import * as engine from "../../../main/ts/service/engine";
import levels from "../../resources/levels/index";
import solutions from "../../resources/solutions/index";
import {chooseOne} from "../utils";

describe("happy case", () => {
    for (const value of Object.values(solutions)) {
        const solution = decodeOrThrow(SolutionDto.decoder, value);
        const level = decodeOrThrow(LevelDto.decoder, (levels as any)[solution.levelId]);
        test(`solution ${solution.id} should solve level ${solution.levelId}`, () => {
            expect(engine.isSolutionValid(level, solution.board, solution.score)).toEqual(undefined);
        });
    }
});

describe("illegal board for level", () => {
    const solution = decodeOrThrow(SolutionDto.decoder, chooseOne(Object.values(solutions)));
    const level = decodeOrThrow(LevelDto.decoder, (levels as any)[solution.levelId]);

    test("should fail if solution board width doesn't match level board width", () => {
        const board = {...solution.board, width: solution.board.width + 1};
        const response = engine.isSolutionValid(level, board, solution.score);
        expect(typeof response).toEqual("string");
        expect(response).toMatch("width");
        expect(response).toMatch(`${level.initialBoard.width}`);
        expect(response).toMatch(`${board.width}`);
    });

    test("should fail if solution board height doesn't match level board height", () => {
        const board = {...solution.board, height: solution.board.height - 1};
        const response = engine.isSolutionValid(level, board, solution.score);
        expect(typeof response).toEqual("string");
        expect(response).toMatch("height");
        expect(response).toMatch(`${level.initialBoard.height}`);
        expect(response).toMatch(`${board.height}`);
    });

    test("should fail if solution board height doesn't match level board height", () => {
        const increment: Instruction = {tag: "Increment"};
        const decrement: Instruction = {tag: "Decrement"};
        const modifiedLevel = {
            ...level, initialBoard: {
                width: 1, height: 1, instructions: [{
                    position: {
                        x: 0, y: 0,
                    }, instruction: increment,
                }],
            },
        };
        const board = {...modifiedLevel.initialBoard, instructions: [{position: {x: 0, y: 0}, instruction: decrement}]};
        const response = engine.isSolutionValid(modifiedLevel, board, solution.score);
        expect(typeof response).toEqual("string");
        expect(response).toMatch("fixed instruction");
    });
});
