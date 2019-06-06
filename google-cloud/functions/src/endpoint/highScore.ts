import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as Firestore from '../service/firestore'
import {JsonDecoder} from "ts.data.json";
import {decode} from "../misc/json";
import * as Score from "../data/Score";
import * as HighScore from "../data/HighScore";

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
        }, "GetHighScoreRequest")
    );
    if (result.tag === "failure") {
        return EndpointException.send(result.error, res);
    }

    return Firestore.getSolutions({levelId: result.value.levelId})
        .then(snapshot => snapshot.docs.map(doc => Score.decoder.decodePromise(doc)))
        .then(promises => Promise.all(promises))
        .then(scores => HighScore.fromScores(result.value.levelId, scores))
        .then(highScore => res.send(highScore));
}
