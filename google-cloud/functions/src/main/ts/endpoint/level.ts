import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";

import * as LevelDto from "../data/dto/LevelDto";
import {badRequest, EndpointResult, forbidden, found, internalServerError, notFound, ok} from "../data/EndpointResult";
import * as InstructionTool from "../data/InstructionTool";
import * as Integer from "../data/Integer";
import * as Level from "../data/Level";
import * as Score from "../data/Score";
import * as Suite from "../data/Suite";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import {map} from "../misc/utils";
import {isSolutionValid} from "../service/engine";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request): Promise<EndpointResult<never | LevelDto.LevelDto | LevelDto.LevelDto[]>> {
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

async function get(req: Request): Promise<EndpointResult<LevelDto.LevelDto | LevelDto.LevelDto[]>> {
    const request =
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
        }, "GetLevelsRequest")
            .decode(req.query);
    if (request instanceof Err) {
        return badRequest(request.error);
    }

    if (typeof request.value.levelId !== "undefined") {
        const level = await Firestore.getLevelById(request.value.levelId);
        if (typeof level === "undefined") {
            return notFound();
        }
        return found(LevelDto.encode(level));
    }

    return Firestore.getLevels(request.value)
        .then(map(LevelDto.encode))
        .then(found);
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
    const blueprint = await Firestore.getBlueprintById(request.value.blueprintId);
    if (typeof blueprint === "undefined") {
        return badRequest(`Blueprint ${request.value.blueprintId} does not exist`);
    }
    if (blueprint.authorId !== user.id) {
        return forbidden(user.id, "publish", "blueprint", request.value.blueprintId);
    }

    const level = Level.fromBlueprint(blueprint);
    const solutionError = isSolutionValid(level, request.value.board, request.value.score);
    if (typeof solutionError !== "undefined") {
        console.warn(`3259a409    Invalid solution posted by user ${user.id}`, solutionError);
        return badRequest(`Invalid solution: ${solutionError}`);
    }

    // TODO
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
        suites: JsonDecoder.oneOf([
            JsonDecoder.array(Suite.decoder, "Suite[]"),
            JsonDecoder.isUndefined(undefined),
        ], "suite[] | undefined"),
        io: JsonDecoder.oneOf([
            Suite.decoder,
            JsonDecoder.isUndefined(undefined),
        ], "suite | undefined"),
        initialBoard: Board.decoder,
        instructionTools: JsonDecoder.array(InstructionTool.decoder, "instructionTools"),
        version: Integer.nonNegativeDecoder,
    }, "PostLevelRequest"));
    if (levelResult.tag === "failure") {
        return badRequest(levelResult.error);
    }
    let suites;
    if (typeof levelResult.value.suites !== "undefined") {
        suites = levelResult.value.suites;
    } else if (typeof levelResult.value.io !== "undefined") {
        suites = [levelResult.value.io];
    } else {
        return badRequest("missing io or suites");
    }
    const level = {
        ...levelResult.value,
        suites,
        createdTime: new Date().getTime(),
        authorId: "root",
    };
    return Firestore.saveLevel(level)
        .then(() => ok());
}
