import {Request, Response} from "express";
import {JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import * as EndpointException from "../data/EndpointException";
import {decoder} from "../data/Integer";
import * as Level from "../data/PostLevelRequest";
import * as Score from "../data/Score";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case "GET":
            return get(req, res);
        case "POST":
            return post(req, res);
        case "PUT":
            return put(req, res);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`],
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
                JsonDecoder.isUndefined(50),
            ], "offset"),
            limit: JsonDecoder.oneOf([
                decoder({minValue: 0, fromString: true}),
                JsonDecoder.isUndefined(0),
            ], "limit"),
        }, "GetLevelsRequest"));
    if (requestResult.tag === "failure") {
        return EndpointException.send(requestResult.error, res);
    }

    return Firestore.getLevels(requestResult.value)
        .then(snapshot => res.send(snapshot.docs.map(doc => doc.data())));
}

async function post(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "publish:blueprints"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const request = decode(req.body, JsonDecoder.object({
        blueprintId: JsonDecoder.string,
        solution: JsonDecoder.object({
            score: Score.decoder,
            board: Board.decoder,
        }, "Solution"),
    }, "Publish blueprint request"));
    if (request.tag === "failure") {
        return EndpointException.send(request.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const blueprintRef = await Firestore.getBlueprintById(request.value.blueprintId);
    const blueprintSnapshot = await blueprintRef.get();
    if (!blueprintSnapshot.exists) {
        return EndpointException.send({
            status: 404,
            messages: [`Blueprint not found: ${request.value.blueprintId}`],
        }, res);
    }
    if (blueprintSnapshot.get("authorId") !== user.id) {
        return EndpointException.send({
            status: 403,
            messages: [`User ${user.id} does not have permission to publish blueprint ${request.value.blueprintId}`],
        }, res);
    }
    // TODO Check solution
    return EndpointException.send({
        status: 500,
        messages: [`Not implemented`],
    }, res);
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
        authorId: "root",
    })
        .then(() => res.send());
}
