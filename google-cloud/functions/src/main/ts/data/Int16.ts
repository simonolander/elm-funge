import {JsonDecoder} from "ts.data.json";
import * as Integer from "./Integer";

export type Int16 = number;

export function fromNumber(value: number): Int16 {
    return (Math.round(isFinite(value) ? value : 0) + 32768) % 65536 - 32768;
}

export const decoder: JsonDecoder.Decoder<Int16> =
    Integer.decoder({minValue: -32768, maxValue: 32767})
        .map(value => fromNumber(value));
