import * as LevelDto from "../../../main/ts/data/dto/LevelDto";
import * as SolutionDto from "../../../main/ts/data/dto/SolutionDto";
import {decodeOrThrow} from "../../../main/ts/misc/json";
import * as engine from "../../../main/ts/service/engine";
import levels from "../../resources/levels/index";
import solutions from "../../resources/solutions/index";

describe("test", () => {
    it("should always pass", () => {
        expect(0).toEqual(0);
    });
});

describe("engine test", () => {
    for (const value of Object.values(solutions)) {
        const solution = decodeOrThrow(SolutionDto.decoder, value);
        const level = decodeOrThrow(LevelDto.decoder, (levels as any)[solution.levelId]);
        it(`solution ${solution.id} should solve level ${solution.levelId}`, () => {
            expect(engine.isSolutionValid(level, solution.board, solution.score)).toEqual(undefined);
        });
    }
});
