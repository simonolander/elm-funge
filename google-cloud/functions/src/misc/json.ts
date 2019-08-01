import {JsonDecoder, Ok} from "ts.data.json";
import * as EndpointException from "../data/EndpointException";
import * as Result from "../data/Result";

export function decode<T>(json: any, decoder: JsonDecoder.Decoder<T>): Result.Result<T, EndpointException.EndpointException> {
    const result = decoder.decode(json);
    if (result instanceof Ok) {
        return Result.success(result.value);
    } else {
        return Result.failure({status: 400, messages: [result.error]});
    }
}
