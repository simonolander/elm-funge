import {JsonDecoder} from "ts.data.json";
import * as Int16 from "./Int16";

export interface IO {
    input: Array<Int16.Int16>,
    output: Array<Int16.Int16>
}

export const decoder: JsonDecoder.Decoder<IO> = JsonDecoder.object({
    input: JsonDecoder.array(Int16.decoder, "input"),
    output: JsonDecoder.array(Int16.decoder, "input"),
}, "IO");
