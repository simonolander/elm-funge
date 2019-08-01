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
        case 'PUT':
            return put(req, res);
        case 'DELETE':
            return del(req, res);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`]
            }, res);
    }
}

async function get(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "read:blueprints"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const requestResult = decode(
        req.query,
        JsonDecoder.object({
            blueprintId: JsonDecoder.oneOf([
                JsonDecoder.string,
                JsonDecoder.isUndefined(undefined)
            ], "blueprintId"),
        }, "GetBlueprintsRequest"));
    if (requestResult.tag === "failure") {
        return EndpointException.send(requestResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    if (typeof requestResult.value.blueprintId !== "undefined") {
        const blueprintSnapshot = await Firestore.getBlueprintById(requestResult.value.blueprintId);
        if (blueprintSnapshot.empty) {
            return res.status(404).send();
        }
        const blueprint = blueprintSnapshot.docs[0].data();
        if (blueprint.authorId !== user.id) {
            return res.status(404).send();
        } else {
            return res.send(blueprint);
        }
    } else {
        return Firestore.getBlueprints({
            authorId: user.id
        })
            .then(snapshot => res.send(snapshot.docs.map(doc => doc.data())))
    }
}

async function put(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "edit:blueprints"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const blueprintResult = decode(req.body, Level.decoder);
    if (blueprintResult.tag === "failure") {
        return EndpointException.send(blueprintResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const existingBlueprint = await Firestore.getBlueprintById(blueprintResult.value.id);
    if (existingBlueprint.empty) {
        const time = Date.now();
        const blueprint = {
            ...blueprintResult.value,
            authorId: user.id,
            createdTime: time,
            modifiedTime: time
        };
        return Firestore.addBlueprint(blueprint)
            .then(ref => ref.get())
            .then(ref => res.send(ref.data()));
    } else {
        if (existingBlueprint.docs[0].get('authorId') !== user.id) {
            return EndpointException.send({
                status: 403,
                messages: [`User ${user.id} does not have permission to edit blueprint ${blueprintResult.value.id}`]
            }, res)
        }
        return Firestore.getDraftDocument(existingBlueprint.docs[0].id)
            .then(ref => ref.set({
                ...blueprintResult.value,
                modifiedTime: Date.now()
            }, {merge: true}))
            .then(() => res.send());
    }
}

async function del(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "edit:blueprints"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const requestResult = decode(req.body, JsonDecoder.object({
        blueprintId: JsonDecoder.string
    }, "DeleteRequest"));
    if (requestResult.tag === "failure") {
        return EndpointException.send(requestResult.error, res);
    }
    const {blueprintId} = requestResult.value;
    const user = await Firestore.getUserBySubject(authResult.value);

    const snapshot = await Firestore.getBlueprintById(blueprintId);
    if (snapshot.empty) {
        return res.send();
    } else {
        // TODO decode snapshot to get some safety
        if (snapshot.docs[0].get('authorId') !== user.id) {
            return EndpointException.send({
                status: 403,
                messages: [`User ${user.id} does not have permission to delete blueprint ${blueprintId}`]
            }, res)
        }
        return Firestore.getBlueprintDocument(snapshot.docs[0].id)
            .then(ref => ref.delete())
            .then(() => res.send());
    }
}
