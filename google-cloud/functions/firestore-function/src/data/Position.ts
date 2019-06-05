import {JsonDecoder} from "ts.data.json";
import * as Integer from "./Integer"

export interface Position {
    readonly x: number,
    readonly y: number
}

export const decoder: JsonDecoder.Decoder<Position> = JsonDecoder.object({
    x: Integer.nonNegativeDecoder,
    y: Integer.nonNegativeDecoder
}, "Position");
