import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import * as Draft from "../data/Draft";
import {
    alreadyDeleted,
    badRequest,
    created, deleted,
    EndpointResult,
    forbidden,
    got, internalServerError,
    notFound,
    updated,
} from "../data/EndpointResult";
import * as Result from "../data/Result";
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
            return badRequest([`Bad request method: ${req.method}`]);
    }
}

async function get(req: Request): Promise<EndpointResult<Draft.Draft | Draft.Draft[]>> {
    const authResult = verifyJwt<Draft.Draft>(req, ["openid", "read:drafts"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const request = JsonDecoder.object({
        draftId: JsonDecoder.oneOf([
            JsonDecoder.string,
            JsonDecoder.isUndefined(undefined),
        ], "draftId | undefined"),
        levelId: JsonDecoder.oneOf([
            JsonDecoder.string,
            JsonDecoder.isUndefined(undefined),
        ], "levelId | undefined"),
    }, "GetDraftRequest").decode(req.query);
    if (request instanceof Err) {
        return badRequest(request.error);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    if (typeof request.value.draftId !== "undefined") {
        const snapshot = await Firestore.getDraftById(request.value.draftId)
            .then(ref => ref.get());
        if (snapshot.exists) {
            const draft = decode(snapshot.data(), Draft.decoder);
            if (draft.tag === "failure") {
                console.warn(`989e047a    Corrupt draft ${request.value.draftId} in firestore`, draft.error);
                return internalServerError(`Corrupt draft ${request.value.draftId} in firestore`);
            }
            if (draft.value.authorId !== user.id) {
                return forbidden(user.id, "read", "draft", request.value.draftId);
            }
            return got(draft.value);
        } else {
            return notFound();
        }
    } else {
        return Firestore.getDrafts({authorId: user.id, levelId: request.value.levelId})
            .then(snapshot => Result.values(snapshot.docs.map(doc => decode(doc, Draft.decoder))))
            .then(got);
    }
}

async function put(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:drafts"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const draftResult = decode(req.body, JsonDecoder.object({
        id: JsonDecoder.string,
        levelId: JsonDecoder.string,
        board: Board.decoder,
    }, "Save draft request"));
    if (draftResult.tag === "failure") {
        return badRequest(draftResult.error);
    }
    const draftRequest = draftResult.value;
    const levelSnapshot = await Firestore.getLevelById(draftRequest.levelId)
        .then(ref => ref.get());
    if (!levelSnapshot.exists) {
        return badRequest(`Level ${draftRequest.levelId} does not exist`);
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
        }).then(() => created());
    } else {
        if (draftSnapshot.get("authorId") !== user.id) {
            return forbidden(user.id, "edit", "draft", draftRequest.id);
        }
        const existingLevelId = draftSnapshot.get("levelId");
        if (existingLevelId !== draftRequest.levelId) {
            return badRequest(`Requested level id ${draftRequest} does not match existing level id ${existingLevelId}`);
        }
        // TODO Check that the board matches too
        return draftRef.set({board: draftRequest.board}, {merge: true})
            .then(() => updated());
    }
}

async function del(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:drafts"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const draftResult = decode(req.query, JsonDecoder.object({
        draftId: JsonDecoder.string,
    }, "Delete draft request"));
    if (draftResult.tag === "failure") {
        return badRequest(draftResult.error);
    }
    const draftRef = await Firestore.getDraftById(draftResult.value.draftId);
    const draftSnapshot = await draftRef.get();
    if (!draftSnapshot.exists) {
        return alreadyDeleted();
    } else {
        if (draftSnapshot.get("authorId") !== user.id) {
            return forbidden(user.id, "delete", "draft", draftResult.value.draftId);
        }
        return draftRef.delete()
            .then(() => deleted());
    }
}
