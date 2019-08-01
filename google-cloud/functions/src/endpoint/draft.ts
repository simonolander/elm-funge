import {Request, Response} from "express";
import {JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import * as EndpointException from "../data/EndpointException";
import * as GetDraftRequest from "../data/GetDraftRequest";
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
    const subject = authResult.value;
    const result = decode(req.query, GetDraftRequest.decoder);
    if (result.tag === "failure") {
        return EndpointException.send(result.error, res);
    }
    const {draftId, levelId} = result.value;
    if (typeof draftId !== "undefined") {
        return Firestore.getUserBySubject(subject)
            .then(ref => Firestore.getDrafts({
                authorId: ref.id,
                draftId,
            }))
            .then(ref => ref.docs.map(doc => doc.data()))
            .then(data =>
                data.length !== 0
                    ? res.send(data[0])
                    : res.status(404).send());
    } else if (typeof levelId !== "undefined") {
        return Firestore.getUserBySubject(subject)
            .then(ref => Firestore.getDrafts({
                authorId: ref.id,
                levelId,
            }))
            .then(ref => ref.docs.map(doc => doc.data()))
            .then(data => res.send(data));
    } else {
        return Firestore.getUserBySubject(subject)
            .then(ref => Firestore.getDrafts({authorId: ref.id}))
            .then(ref => ref.docs.map(doc => doc.data()))
            .then(data => res.send(data));
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
