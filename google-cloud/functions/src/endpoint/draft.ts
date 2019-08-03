import {Request, Response} from "express";
import {JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import * as Draft from "../data/Draft";
import * as EndpointException from "../data/EndpointException";
import * as Result from "../data/Result";
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

/**
 * draftId: string | undefined
 * levelId: string | undefined
 */
async function get(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "read:drafts"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const request = decode(req.query, JsonDecoder.object({
        draftId: JsonDecoder.oneOf([
            JsonDecoder.string,
            JsonDecoder.isUndefined(undefined),
        ], "draftId | undefined"),
        levelId: JsonDecoder.oneOf([
            JsonDecoder.string,
            JsonDecoder.isUndefined(undefined),
        ], "levelId | undefined"),
    }, "GetDraftRequest"));
    if (request.tag === "failure") {
        return EndpointException.send(request.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    if (typeof request.value.draftId !== "undefined") {
        const snapshot = await Firestore.getDraftById(request.value.draftId)
            .then(ref => ref.get());
        if (snapshot.exists) {
            const draft = decode(snapshot.data(), Draft.decoder);
            if (draft.tag === "failure") {
                console.warn(`989e047a    Corrupt draft ${request.value.draftId} in firestore`, draft.error.messages);
                throw new Error(`Corrupt draft ${request.value.draftId} in firestore`);
            }
            if (draft.value.authorId !== user.id) {
                return EndpointException.send({
                    status: 403,
                    messages: [`User ${user.id} does not have permission to read draft ${request.value.draftId}`],
                }, res);
            }
            return res.send(draft.value);
        } else {
            return res.status(404).send();
        }
    } else {
        return Firestore.getDrafts({authorId: user.id, levelId: request.value.levelId})
            .then(snapshot => Result.values(snapshot.docs.map(doc => decode(doc, Draft.decoder))))
            .then(drafts => res.send(drafts));
    }
}

async function put(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "edit:drafts"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const draftResult = decode(req.body, JsonDecoder.object({
        id: JsonDecoder.string,
        levelId: JsonDecoder.string,
        board: Board.decoder,
    }, "Save draft request"));
    if (draftResult.tag === "failure") {
        return EndpointException.send(draftResult.error, res);
    }
    const draftRequest = draftResult.value;
    const levelSnapshot = await Firestore.getLevelById(draftRequest.levelId)
        .then(ref => ref.get());
    if (!levelSnapshot.exists) {
        return EndpointException.send({
            status: 404,
            messages: [`Level ${draftRequest.levelId} does not exist`],
        }, res);
    }
    const draftRef = await Firestore.getDraftById(draftRequest.id);
    const draftSnapshot = await draftRef.get();
    if (!draftSnapshot.exists) {
        const time = Date.now();
        return draftRef.set({
            ...draftResult.value,
            authorId: user.id,
            createdTime: time,
            modifiedTime: time,
        }).then(() => res.send());
    } else {
        if (draftSnapshot.get("authorId") !== user.id) {
            return EndpointException.send({
                status: 403,
                messages: [`User ${user.id} does not have permission to edit draft ${draftRequest.id}`],
            }, res);
        }
        const existingLevelId = draftSnapshot.get("levelId");
        if (existingLevelId !== draftRequest.levelId) {
            return EndpointException.send({
                status: 400,
                messages: [`Requested level id ${draftRequest} does not match existing level id ${existingLevelId}`],
            }, res);
        }
        // TODO Check that the board matches too
        return draftRef.set({board: draftRequest.board}, {merge: true})
            .then(() => res.send());
    }
}

async function del(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "edit:drafts"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const draftResult = decode(req.body, JsonDecoder.object({
        draftId: JsonDecoder.string,
    }, "Delete draft request"));
    if (draftResult.tag === "failure") {
        return EndpointException.send(draftResult.error, res);
    }
    const draftRef = await Firestore.getDraftById(draftResult.value.draftId);
    const draftSnapshot = await draftRef.get();
    if (!draftSnapshot.exists) {
        return res.send();
    } else {
        if (draftSnapshot.get("authorId") !== user.id) {
            return EndpointException.send({
                status: 403,
                messages: [`User ${user.id} does not have permission to delete draft ${draftResult.value.draftId}`],
            }, res);
        }
        return draftRef.delete()
            .then(() => res.send());
    }
}
