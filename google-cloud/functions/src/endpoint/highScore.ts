import {Request} from "express";
import {JsonDecoder} from "ts.data.json";

import {badRequest, EndpointResult, found} from "../data/EndpointResult";
import * as HighScore from "../data/HighScore";
import * as Result from "../data/Result";
import * as Solution from "../data/Solution";
import {decode} from "../misc/json";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request): Promise<EndpointResult<any>> {
    switch (req.method) {
        case "GET":
            return get(req);
        default:
            return badRequest(`Bad request method: ${req.method}`);
    }
}

async function get(req: Request): Promise<EndpointResult<any>> {
    const result = decode(
        req.query,
        JsonDecoder.object({
            levelId: JsonDecoder.string,
        }, "{ levelId: string }"),
    );
    if (result.tag === "failure") {
        return badRequest(result.error);
    }

    return Firestore.getSolutions({levelId: result.value.levelId})
        .then(snapshot => snapshot.docs.map(doc => decode(doc.data(), Solution.decoder)))
        .then(results => Result.values(results))
        .then(solutions => solutions.map(solution => solution.score))
        .then(scores => HighScore.fromScores(result.value.levelId, scores))
        .then(highScore => found(highScore));
}
