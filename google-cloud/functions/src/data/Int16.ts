import {JsonDecoder} from "ts.data.json";
import * as Integer from "./Integer";

export class Int16 {
    private readonly value: number;

    constructor(value: number) {
        this.value = Int16.normalize(value);
    }

    private static normalize(value: number): number {
        return (Math.round(isFinite(value) ? value : 0) + 32768) % 65536 - 32768;
    }

    public add(other: Int16) {
        return new Int16(this.value + other.value)
    }
}

export const decoder: JsonDecoder.Decoder<Int16> =
    Integer.decoder({minValue: -32768, maxValue: 32767})
        .map(value => new Int16(value));
