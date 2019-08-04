import {JsonDecoder, Ok} from "ts.data.json";

import * as Result from "../data/Result";

export function decode<T>(json: any, decoder: JsonDecoder.Decoder<T>): Result.Result<T, string> {
    const result = decoder.decode(json);
    if (result instanceof Ok) {
        return Result.success(result.value);
    } else {
        return Result.failure(result.error);
    }
}
