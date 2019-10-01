import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import * as BlueprintDto from "../data/dto/BlueprintDto";
import {badRequest, EndpointResult, forbidden, found, notFound, ok} from "../data/EndpointResult";
import * as InstructionTool from "../data/InstructionTool";
import * as Suite from "../data/Suite";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import {map} from "../misc/utils";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request): Promise<EndpointResult<any>> {
    switch (req.method) {
        case "GET":
            return get(req);
        case "PUT":
            return put(req);
        case "DELETE":
            return del(req);
        default:
            return badRequest(`Bad request method: ${req.method}`);
    }
}

async function get(req: Request): Promise<EndpointResult<BlueprintDto.BlueprintDto | BlueprintDto.BlueprintDto[]>> {
    const authResult = verifyJwt<BlueprintDto.BlueprintDto>(req, ["openid", "read:blueprints"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const request = JsonDecoder.object({
        blueprintId: JsonDecoder.oneOf([
            JsonDecoder.string,
            JsonDecoder.isUndefined(undefined),
        ], "blueprintId"),
    }, "GetBlueprintsRequest")
        .decode(req.query);
    if (request instanceof Err) {
        return badRequest(request.error);
    }

    const user = await Firestore.getUserBySubject(authResult.value);
    if (typeof request.value.blueprintId !== "undefined") {
        const blueprint = await Firestore.getBlueprintById(request.value.blueprintId);
        if (typeof blueprint === "undefined") {
            return notFound();
        }
        if (blueprint.authorId !== user.id) {
            return forbidden(user.id, "read", "blueprint", request.value.blueprintId);
        } else {
            return found(BlueprintDto.encode(blueprint));
        }
    } else {
        return Firestore.getBlueprints({authorId: user.id})
            .then(map(BlueprintDto.encode))
            .then(found);
    }
}

async function put(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:blueprints"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const request = JsonDecoder.object({
        id: JsonDecoder.string,
        index: JsonDecoder.number,
        name: JsonDecoder.string,
        description: JsonDecoder.array(JsonDecoder.string, "description"),
        suites: JsonDecoder.array(Suite.decoder, "Suite[]"),
        initialBoard: Board.decoder,
        instructionTools: JsonDecoder.array(InstructionTool.decoder, "instructionTools"),
    }, "BlueprintDto").decode(req.body);
    if (request instanceof Err) {
        return badRequest(request.error);
    }

    const user = await Firestore.getUserBySubject(authResult.value);
    const existingBlueprint = await Firestore.getBlueprintById(request.value.id);
    if (typeof existingBlueprint !== "undefined") {
        if (existingBlueprint.authorId !== user.id) {
            return forbidden(user.id, "edit", "blueprint", request.value.id);
        }
    }

    const time = Date.now();
    const blueprint: BlueprintDto.BlueprintDto = {
        ...request.value,
        authorId: user.id,
        createdTime: time,
        modifiedTime: time,
        version: 1,
    };

    return Firestore.saveBlueprint(blueprint)
        .then(() => ok());
}

async function del(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:blueprints"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const request = decode(req.query, JsonDecoder.object({
        blueprintId: JsonDecoder.string,
    }, "DeleteRequest"));
    if (request.tag === "failure") {
        return badRequest(request.error);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const blueprint = await Firestore.getBlueprintById(request.value.blueprintId);
    if (typeof blueprint === "undefined") {
        return ok();
    }

    if (blueprint.authorId !== user.id) {
        return forbidden(user.id, "delete", "blueprint", request.value.blueprintId);
    }
    return Firestore.deleteBlueprint(request.value.blueprintId)
        .then(() => ok());
}
