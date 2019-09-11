import * as Int16 from "../../../main/ts/data/Int16";
import {randomInteger} from "../utils";

test.each([
    [0, 0],
    [-1, -1],
    [1, 1],
    [40000, -25536],
    [-40000, 25536],
    [32768, -32768],
    [-32768, -32768],
    [-32769, 32767],
    [32767, 32767],
    [32769, -32767],
    [65535, -1],
    [65536, 0],
    [65537, 1],
    [655370000, 10000],
    [1310740000, 20000],
    [1966110000, 30000],
    [4295098369, 1],
    [281487861809153, 1],
    [4294836225, 1],
    [281462092005375, -1],
    [-10, -10],
    [-655370, -10],
    [-42950983690, -10],
    [-2814878618091530, -10],
])("Int16.fromNumber(%i) should be equal to %i", (n, expected) => {
    expect(Int16.fromNumber(n)).toEqual(expected);
});

test("fromNumber should be a fixed function", () => {
    const n = Int16.fromNumber(randomInteger(100000) - 50000);
    expect(Int16.fromNumber(n)).toEqual(n);
});
