import {JsonDecoder} from "ts.data.json";
import * as Integer from "./Integer"

export interface Score {
    readonly numberOfSteps: number,
    readonly numberOfInstructions: number
}

export const decoder: JsonDecoder.Decoder<Score> = JsonDecoder.object({
    numberOfSteps: Integer.nonNegativeDecoder,
    numberOfInstructions: Integer.nonNegativeDecoder
}, "Score");
