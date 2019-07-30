import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as Level from "../data/PostLevelRequest";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import * as Firestore from '../service/firestore'
import {JsonDecoder} from "ts.data.json";
import {decoder} from "../data/Integer";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case 'GET':
            return get(req, res);
        case 'POST':
            return post(req, res,);
        case 'PUT':
            return put(req, res,);
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
            offset: JsonDecoder.oneOf([
                decoder({minValue: 0, fromString: true}),
                JsonDecoder.isUndefined(50)
            ], "offset"),
            limit: JsonDecoder.oneOf([
                decoder({minValue: 0, fromString: true}),
                JsonDecoder.isUndefined(0)
            ], "limit"),
        }, "GetLevelsRequest"));
    if (requestResult.tag === "failure") {
        return EndpointException.send(requestResult.error, res);
    }

    return Firestore.getLevels(requestResult.value)
        .then(snapshot => res.send(snapshot.docs.map(doc => doc.data())));
}

async function post(req: Request, res: Response): Promise<Response> {
    const scopes = ["openid", "publish:blueprints"]; // TODO What is this method doing?
    const authResult = verifyJwt(req, scopes);
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
        .then(() => res.send());
}

/* TODO REMOVE */
async function put(req: Request, res: Response): Promise<Response> {
    const levelResult = decode(req.body, Level.decoder);
    if (levelResult.tag === "failure") {
        return EndpointException.send(levelResult.error, res);
    }
    return Firestore.addLevel({
        ...levelResult.value,
        createdTime: new Date().getTime(),
        authorId: "root"
    })
        .then(() => res.send());
}
