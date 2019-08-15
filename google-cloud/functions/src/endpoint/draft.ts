import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import * as Draft from "../data/Draft";
import {
    badRequest,
    conflictingId,
    corruptData,
    EndpointResult,
    forbidden,
    found,
    notFound,
    ok,
} from "../data/EndpointResult";
import * as Level from "../data/Level";
import * as Result from "../data/Result";
import {verifyJwt} from "../misc/auth";
import {decode, maybe} from "../misc/json";
import {isBoardValid} from "../service/engine";
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

async function get(req: Request): Promise<EndpointResult<Draft.Draft | Draft.Draft[]>> {
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
        const draft = await Firestore.getDraftById(request.value.draftId)
            .then(ref => ref.get())
            .then(data => maybe(Draft.decoder).decode(data));
        if (draft instanceof Err) {
            return corruptData("drafts", request.value.draftId, draft.error);
        }
        if (typeof draft.value === "undefined") {
            return notFound();
        }
        if (draft.value.authorId !== user.id) {
            return forbidden(user.id, "read", "draft", request.value.draftId);
        }
        return found(draft.value);
    } else {
        return Firestore.getDrafts({authorId: user.id, levelId: request.value.levelId})
            .then(snapshot => Result.values(snapshot.docs.map(doc => decode(doc.data(), Draft.decoder))))
            .then(found);
    }
}

async function put(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:drafts"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const request = decode(req.body, JsonDecoder.object({
        id: JsonDecoder.string,
        levelId: JsonDecoder.string,
        board: Board.decoder,
    }, "Save draft request"));
    if (request.tag === "failure") {
        return badRequest(request.error);
    }
    const time = Date.now();
    const draft: Draft.Draft = {
        ...request.value,
        authorId: user.id,
        createdTime: time,
        modifiedTime: time,
    };
    const level = await Firestore.getLevelById(request.value.levelId)
        .then(ref => ref.get())
        .then(snapshot => snapshot.data())
        .then(data => maybe(Level.decoder).decode(data));
    if (level instanceof Err) {
        return corruptData("levels", request.value.levelId, level.error);
    }
    if (typeof level.value === "undefined") {
        return badRequest(`Level ${request.value.levelId} does not exist`);
    }
    const draftRef = await Firestore.getDraftById(request.value.id);
    const existingDraft = await draftRef.get()
        .then(snapshot => snapshot.data())
        .then(data => maybe(Draft.decoder).decode(data));
    if (existingDraft instanceof Err) {
        return corruptData("drafts", request.value.id, existingDraft.error);
    }
    if (typeof existingDraft.value !== "undefined") {
        if (existingDraft.value.authorId !== user.id) {
            return conflictingId();
        }
        if (existingDraft.value.levelId !== request.value.levelId) {
            return badRequest(`Requested level id ${request.value} does not match existing level id ${existingDraft.value.levelId}`);
        }
    }
    const boardError = isBoardValid(level.value, request.value.board);
    if (typeof boardError !== "undefined") {
        return badRequest(boardError);
    }
    return draftRef.set(draft)
        .then(() => ok());
}

async function del(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:drafts"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const request = decode(req.query, JsonDecoder.object({
        draftId: JsonDecoder.string,
    }, "Delete draft request"));
    if (request.tag === "failure") {
        return badRequest(request.error);
    }
    const draftRef = await Firestore.getDraftById(request.value.draftId);
    const draftSnapshot = await draftRef.get();
    if (!draftSnapshot.exists) {
        return ok();
    } else {
        if (draftSnapshot.get("authorId") !== user.id) {
            return forbidden(user.id, "delete", "draft", request.value.draftId);
        }
        return draftRef.delete()
            .then(() => ok());
    }
}
