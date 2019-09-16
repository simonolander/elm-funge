import {JsonDecoder} from "ts.data.json";
import * as Int16 from "./Int16";

export interface Suite {
    input: Int16.Int16[];
    output: Int16.Int16[];
}

export const decoder: JsonDecoder.Decoder<Suite> = JsonDecoder.object({
    input: JsonDecoder.array(Int16.decoder, "input"),
    output: JsonDecoder.array(Int16.decoder, "input"),
}, "Suite");
