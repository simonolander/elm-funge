import {expect} from "chai";
import * as Level from "../../../main/ts/data/Level";
import * as Solution from "../../../main/ts/data/Solution";
import {decodeOrThrow} from "../../../main/ts/misc/json";
import * as engine from "../../../main/ts/service/engine";
import levels from "../../resources/levels/index";
import solutions from "../../resources/solutions/index";

describe("test", () => {
    it("should always pass", () => {
        expect(true).to.equal(true);
    });
});

describe("engine test", () => {
    for (const value of Object.values(solutions)) {
        const solution = decodeOrThrow(Solution.decoder, value);
        const level = decodeOrThrow(Level.decoder, (levels as any)[solution.levelId]);
        it (`solution ${solution.id} should solve level ${solution.levelId}`, () => {
            expect(engine.isSolutionValid(level, solution.board, solution.score)).to.equal(undefined);
        });
    }
});
