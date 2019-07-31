import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as Firestore from '../service/firestore'
import {JsonDecoder} from "ts.data.json";
import {decode} from "../misc/json";
import * as HighScore from "../data/HighScore";
import * as Result from "../data/Result";
import * as Solution from "../data/Solution";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case 'GET':
            return get(req, res);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`]
            }, res);
    }
}

async function get(req: Request, res: Response): Promise<Response> {
    const result = decode(
        req.query,
        JsonDecoder.object({
            levelId: JsonDecoder.string
        }, "{ levelId: string }")
    );
    if (result.tag === "failure") {
        return EndpointException.send(result.error, res);
    }

    return Firestore.getSolutions({levelId: result.value.levelId})
        .then(snapshot => snapshot.docs.map(doc => decode(doc, Solution.decoder)))
        .then(results => Result.values(results))
        .then(solutions => solutions.map(solution => solution.score))
        .then(scores => HighScore.fromScores(result.value.levelId, scores))
        .then(highScore => res.send(highScore));
}
