import {JsonDecoder} from "ts.data.json";
import * as Integer from "./Integer";

export interface Position {
    readonly x: number;
    readonly y: number;
}

export const decoder: JsonDecoder.Decoder<Position> = JsonDecoder.object({
    x: Integer.nonNegativeDecoder,
    y: Integer.nonNegativeDecoder,
}, "Position");

export function compareFn(a: Position, b: Position) {
    if (a.x !== b.x) {
        return a.x < b.x ? -1 : 1;
    }

    if (a.y !== b.y) {
        return a.y < b.y ? -1 : 1;
    }

    return 0;
}
