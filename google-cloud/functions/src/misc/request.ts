import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import {badRequest, EndpointResult} from "../data/EndpointResult";
import {Scope} from "../data/Scope";
import {getUserBySubject} from "../service/firestore";
import {verifyJwt} from "./auth";

export async function authQuery<P, T>(
    req: Request,
    scopes: Scope[],
    decoder: JsonDecoder.Decoder<P>,
    endpoint: (userId: string, parameters: P) => Promise<EndpointResult<T>>,
): Promise<EndpointResult<T>> {
    const auth = verifyJwt<T>(req, scopes);
    if (auth.tag === "failure") {
        return auth.error;
    }
    const user = await getUserBySubject(auth.value);
    const decode = decoder.decode(req.query);
    if (decode instanceof Err) {
        return badRequest(decode.error);
    }
    return endpoint(user.id, decode.value);
}
