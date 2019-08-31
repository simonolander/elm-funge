import * as Json from "ts.data.json";

import * as Result from "../data/Result";

export function decode<T>(json: any, decoder: Json.JsonDecoder.Decoder<T>): Result.Result<T, string> {
    const result = decoder.decode(json);
    if (result instanceof Json.Ok) {
        return Result.success(result.value);
    } else {
        return Result.failure(result.error);
    }
}

export function maybe<T>(decoder: Json.JsonDecoder.Decoder<T>): Json.JsonDecoder.Decoder<T | undefined> {
    return Json.JsonDecoder.oneOf([decoder, Json.JsonDecoder.isUndefined(undefined)], "maybe");
}

export function decodeOrThrow<T>(decoder: Json.JsonDecoder.Decoder<T>, value: any): T {
    const result = decoder.decode(value);
    if (result instanceof Json.Err) {
        throw new Error(result.error);
    }
    return result.value;
}
