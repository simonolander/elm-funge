import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as Level from "../data/Level";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import * as Firestore from '../service/firestore'

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
    const offset = Number.parseInt(req.query.offset || 0);
    const limit = Number.parseInt(req.query.limit || 50);
    return Firestore.getLevels({offset, limit})
        .then(data => res.send(data));
}

async function post(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const subject = authResult.value;
    const levelResult = decode(req.body, Level.decoder);
    if (levelResult.tag === "failure") {
        return EndpointException.send(levelResult.error, res);
    }
    const user = await Firestore.getUserBySubject(subject);
    return Firestore.addLevel({
        ...levelResult.value,
        createdTime: new Date().getTime(),
        authorId: user.id
    })
        .then(data => res.send(data));
}
