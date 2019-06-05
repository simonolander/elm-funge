import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as Level from "../data/PostLevelRequest";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import * as Firestore from '../service/firestore'
import {JsonDecoder} from "ts.data.json";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case 'GET':
            return get(req, res);
        case 'POST':
            return post(req, res,);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`]
            }, res);
    }
}

async function get(req: Request, res: Response): Promise<Response> {
    const requestResult = decode(
        req.query,
        JsonDecoder.object({
            campaignId: JsonDecoder.string,
            offset: JsonDecoder.number,
            limit: JsonDecoder.number
        }, "GetLevelsRequest"));
    if (requestResult.tag === "failure") {
        return EndpointException.send(requestResult.error, res);
    }

    return Firestore.getLevels(requestResult.value)
        .then(data => res.send(data));
}

async function post(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const levelResult = decode(req.body, Level.decoder);
    if (levelResult.tag === "failure") {
        return EndpointException.send(levelResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    return Firestore.addLevel({
        ...levelResult.value,
        createdTime: new Date().getTime(),
        authorId: user.id
    })
        .then(data => res.send(data));
}
