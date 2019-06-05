import {JsonDecoder, Ok} from "ts.data.json";
import * as Result from "../data/Result";
import * as EndpointException from "../data/EndpointException";

export function decode<T>(json: any, decoder: JsonDecoder.Decoder<T>): Result.Result<T, EndpointException.EndpointException> {
    let result = decoder.decode(json);
    if (result instanceof Ok) {
        return Result.success(result.value);
    } else {
        return Result.failure({status: 400, messages: [result.error]});
    }
}
