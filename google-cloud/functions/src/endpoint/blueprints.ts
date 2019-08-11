import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Blueprint from "../data/Blueprint";

import {
    badRequest,
    corruptData,
    EndpointResult,
    forbidden,
    found,
    notFound,
    ok,
} from "../data/EndpointResult";
import {fromDecodeResult, values} from "../data/Result";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
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

async function get(req: Request): Promise<EndpointResult<Blueprint.Blueprint | Blueprint.Blueprint[]>> {
    const authResult = verifyJwt<Blueprint.Blueprint>(req, ["openid", "read:blueprints"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const request = decode(
        req.query,
        JsonDecoder.object({
            blueprintId: JsonDecoder.oneOf([
                JsonDecoder.string,
                JsonDecoder.isUndefined(undefined),
            ], "blueprintId"),
        }, "GetBlueprintsRequest"));
    if (request.tag === "failure") {
        return badRequest(request.error);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    if (typeof request.value.blueprintId !== "undefined") {
        const blueprintSnapshot = await Firestore.getBlueprintById(request.value.blueprintId)
            .then(ref => ref.get());
        if (!blueprintSnapshot.exists) {
            return notFound();
        }
        const blueprint = Blueprint.decoder.decode(blueprintSnapshot.data());
        if (blueprint instanceof Err) {
            return corruptData("blueprints", request.value.blueprintId, blueprint.error);
        }
        if (blueprint.value.authorId !== user.id) {
            return forbidden(user.id, "read", "blueprint", request.value.blueprintId);
        } else {
            return found(blueprint.value);
        }
    } else {
        return Firestore.getBlueprints({
            authorId: user.id,
        })
            .then(snapshot => snapshot.docs.map(doc => fromDecodeResult(Blueprint.decoder.decode(doc.data()))))
            .then(values)
            .then(found);
    }
}

async function put(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:blueprints"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const request = decode(req.body, Blueprint.decoder);
    if (request.tag === "failure") {
        return badRequest(request.error);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const ref = await Firestore.getBlueprintById(request.value.id);
    const blueprint = await ref.get()
        .then(r => r.data());
    if (typeof blueprint === "undefined") {
        const time = Date.now();
        const newBlueprint: Blueprint.Blueprint = {
            ...request.value,
            authorId: user.id,
            createdTime: time,
            modifiedTime: time,
        };
        return ref.set(newBlueprint)
            .then(() => ok());
    } else {
        if (blueprint.authorId !== user.id) {
            return forbidden(user.id, "edit", "blueprint", request.value.id);
        }
        return ref.set({...request.value, modifiedTime: Date.now()}, {merge: true})
            .then(() => ok());
    }
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
    const snapshot = await Firestore.getBlueprintById(request.value.blueprintId)
        .then(ref => ref.get());
    if (!snapshot.exists) {
        return ok();
    }

    const blueprint = Blueprint.decoder.decode(snapshot.data());
    if (blueprint instanceof Err) {
        return corruptData("blueprints", request.value.blueprintId, blueprint.error);
    }
    if (blueprint.value.authorId !== user.id) {
        return forbidden(user.id, "delete", "blueprint", request.value.blueprintId);
    }
    return snapshot.ref.delete()
        .then(() => ok());
}
