import {Request, Response} from "express";
import {JsonDecoder} from "ts.data.json";
import * as Blueprint from "../data/Blueprint";
import * as Board from "../data/Board";
import * as EndpointException from "../data/EndpointException";
import * as InstructionTool from "../data/InstructionTool";
import {decoder, default as Integer} from "../data/Integer";
import * as IO from "../data/IO";
import * as Level from "../data/Level";
import * as Score from "../data/Score";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import {isSolutionValid} from "../service/engine";
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
        score: Score.decoder,
        board: Board.decoder,
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
    const blueprint = decode(blueprintSnapshot.data(), Blueprint.decoder);
    if (blueprint.tag === "failure") {
        console.warn(`2f275279    Corrupted data for blueprint ${request.value.blueprintId}`, ...blueprint.error.messages);
        return EndpointException.send({
            ...blueprint.error, status: 500,
        }, res);
    }
    if (blueprint.value.authorId !== user.id) {
        return EndpointException.send({
            status: 403,
            messages: [`User ${user.id} does not have permission to publish blueprint ${request.value.blueprintId}`],
        }, res);
    }

    const level = Level.fromBlueprint(blueprint.value);
    const solutionError = isSolutionValid(level, request.value.board, request.value.score);
    if (typeof solutionError !== "undefined") {
        console.warn(`3259a409    Invalid solution posted by user ${user.id}`, solutionError);
        return EndpointException.send({
            messages: [solutionError],
            status: 400,
        }, res);
    }

    return EndpointException.send({
        status: 500,
        messages: [`Not implemented`],
    }, res);
}

/* TODO REMOVE */
async function put(req: Request, res: Response): Promise<Response> {
    const levelResult = decode(req.body, JsonDecoder.object({
        id: JsonDecoder.string,
        index: Integer.nonNegativeDecoder,
        campaignId: JsonDecoder.string,
        name: JsonDecoder.string,
        description: JsonDecoder.array(JsonDecoder.string, "description"),
        io: IO.decoder,
        initialBoard: Board.decoder,
        instructionTools: JsonDecoder.array(InstructionTool.decoder, "instructionTools"),
        version: Integer.nonNegativeDecoder,
    }, "PostLevelRequest"));
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
