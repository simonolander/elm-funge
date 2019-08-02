import {Request, Response} from "express";
import {JsonDecoder} from "ts.data.json";
import * as Blueprint from "../data/Blueprint";
import * as EndpointException from "../data/EndpointException";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case "GET":
            return get(req, res);
        case "PUT":
            return put(req, res);
        case "DELETE":
            return del(req, res);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`],
            }, res);
    }
}

async function get(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "read:blueprints"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
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
        return EndpointException.send(request.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    if (typeof request.value.blueprintId !== "undefined") {
        const blueprintSnapshot = await Firestore.getBlueprintById(request.value.blueprintId)
            .then(ref => ref.get());
        const blueprint = blueprintSnapshot.data();
        if (typeof blueprint === "undefined") {
            return res.status(404).send();
        }
        if (blueprint.authorId !== user.id) {
            return res.status(403).send();
        } else {
            return res.send(blueprint);
        }
    } else {
        return Firestore.getBlueprints({
            authorId: user.id,
        })
            .then(snapshot => res.send(snapshot.docs.map(doc => doc.data())));
    }
}

async function put(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "edit:blueprints"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const request = decode(req.body, Blueprint.decoder);
    if (request.tag === "failure") {
        return EndpointException.send(request.error, res);
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
            .then(() => res.send());
    } else {
        if (blueprint.authorId !== user.id) {
            return EndpointException.send({
                status: 403,
                messages: [`User ${user.id} does not have permission to edit blueprint ${request.value.id}`],
            }, res);
        }
        return ref.set({...request.value, modifiedTime: Date.now()}, {merge: true})
            .then(() => res.send());
    }
}

async function del(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "edit:blueprints"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const request = decode(req.body, JsonDecoder.object({
        blueprintId: JsonDecoder.string,
    }, "DeleteRequest"));
    if (request.tag === "failure") {
        return EndpointException.send(request.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const snapshot = await Firestore.getBlueprintById(request.value.blueprintId)
        .then(ref => ref.get());
    if (!snapshot.exists) {
        return res.send();
    } else {
        // TODO decode snapshot to get some safety
        if (snapshot.get("authorId") !== user.id) {
            return EndpointException.send({
                status: 403,
                messages: [`User ${user.id} does not have permission to delete blueprint ${request.value.blueprintId}`],
            }, res);
        }
        return snapshot.ref.delete()
            .then(() => res.send());
    }
}
