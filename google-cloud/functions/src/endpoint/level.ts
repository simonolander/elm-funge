import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Blueprint from "../data/Blueprint";
import * as Board from "../data/Board";

import {
    badRequest,
    EndpointResult,
    forbidden,
    got,
    internalServerError,
    notFound,
    updated,
} from "../data/EndpointResult";
import * as InstructionTool from "../data/InstructionTool";
import * as Integer from "../data/Integer";
import * as IO from "../data/IO";
import * as Level from "../data/Level";
import {values} from "../data/Result";
import * as Score from "../data/Score";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import {isSolutionValid} from "../service/engine";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request): Promise<EndpointResult<any>> {
    switch (req.method) {
        case "GET":
            return get(req);
        case "POST":
            return post(req);
        case "PUT":
            return put(req);
        default:
            return badRequest(`Bad request method: ${req.method}`);
    }
}

async function get(req: Request): Promise<EndpointResult<Level.Level | Level.Level[]>> {
    const requestResult = decode(
        req.query,
        JsonDecoder.object({
            campaignId: JsonDecoder.oneOf([
                JsonDecoder.string,
                JsonDecoder.isUndefined(undefined),
            ], "campaignId"),
            levelId: JsonDecoder.oneOf([
                JsonDecoder.string,
                JsonDecoder.isUndefined(undefined),
            ], "campaignId"),
            offset: JsonDecoder.oneOf([
                Integer.decoder({minValue: 0, fromString: true}),
                JsonDecoder.isUndefined(undefined),
            ], "offset"),
            limit: JsonDecoder.oneOf([
                Integer.decoder({minValue: 0, fromString: true}),
                JsonDecoder.isUndefined(undefined),
            ], "limit"),
        }, "GetLevelsRequest"));
    if (requestResult.tag === "failure") {
        return badRequest(requestResult.error);
    }

    if (typeof requestResult.value.levelId !== "undefined") {
        const documentSnapshot = await Firestore.getLevelById(requestResult.value.levelId)
            .then(ref => ref.get());
        if (!documentSnapshot.exists) {
            return notFound();
        }
        const level =  Level.decoder.decode(documentSnapshot.data());
        if (level instanceof Err) {
            console.warn(`ed00fc10    Corrupted data for level ${requestResult.value.levelId}`, level.error);
            return internalServerError(`Corrupted data for level ${requestResult.value.levelId}`);
        }
        return got(level.value);
    }

    return Firestore.getLevels(requestResult.value)
        .then(snapshot => snapshot.docs.map(doc => doc.data()))
        .then(data => data.map(Level.decoder.decode))
        .then(results => got(values(results)));
}

async function post(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "publish:blueprints"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const request = decode(req.body, JsonDecoder.object({
        blueprintId: JsonDecoder.string,
        score: Score.decoder,
        board: Board.decoder,
    }, "Publish blueprint request"));
    if (request.tag === "failure") {
        return badRequest(request.error);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const blueprintRef = await Firestore.getBlueprintById(request.value.blueprintId);
    const blueprintSnapshot = await blueprintRef.get();
    if (!blueprintSnapshot.exists) {
        return notFound();
    }
    const blueprint = decode(blueprintSnapshot.data(), Blueprint.decoder);
    if (blueprint.tag === "failure") {
        console.warn(`2f275279    Corrupted data for blueprint ${request.value.blueprintId}`, ...blueprint.error);
        return internalServerError(`Corrupted data for blueprint ${request.value.blueprintId}`);
    }
    if (blueprint.value.authorId !== user.id) {
        return forbidden(user.id, "publish", "blueprint", request.value.blueprintId);
    }

    const level = Level.fromBlueprint(blueprint.value);
    const solutionError = isSolutionValid(level, request.value.board, request.value.score);
    if (typeof solutionError !== "undefined") {
        console.warn(`3259a409    Invalid solution posted by user ${user.id}`, solutionError);
        return badRequest([`Invalid solution posted by user ${user.id}`, solutionError]);
    }

    return internalServerError("not implemented");
}

/* TODO REMOVE */
async function put(req: Request): Promise<EndpointResult<never>> {
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
        return badRequest(levelResult.error);
    }
    const level: Level.Level = {
        ...levelResult.value,
        createdTime: new Date().getTime(),
        authorId: "root",
    };
    return Firestore.getLevelById(levelResult.value.id)
        .then(ref => ref.set(level))
        .then(() => updated());
}
