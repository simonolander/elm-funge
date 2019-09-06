import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import * as Draft from "../data/Draft";
import * as DraftDto from "../data/dto/DraftDto";
import {badRequest, conflictingId, EndpointResult, forbidden, found, notFound, ok} from "../data/EndpointResult";
import {verifyJwt} from "../misc/auth";
import {map} from "../misc/utils";
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

async function get(req: Request): Promise<EndpointResult<DraftDto.DraftDto | DraftDto.DraftDto[]>> {
    const authResult = verifyJwt<DraftDto.DraftDto>(req, ["openid", "read:drafts"]);
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
        const draft = await Firestore.getDraftById(request.value.draftId);
        if (typeof draft === "undefined") {
            return notFound();
        }
        if (draft.authorId !== user.id) {
            return forbidden(user.id, "read", "draft", request.value.draftId);
        }
        return found(DraftDto.encode(draft));
    } else {
        return Firestore.getDrafts({authorId: user.id, levelId: request.value.levelId})
            .then(map(DraftDto.encode))
            .then(found);
    }
}

async function put(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:drafts"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const request = JsonDecoder.object({
        id: JsonDecoder.string,
        levelId: JsonDecoder.string,
        board: Board.decoder,
    }, "Save draft request").decode(req.body);
    if (request instanceof Err) {
        return badRequest(request.error);
    }
    const time = Date.now();
    const draft: Draft.Draft = {
        ...request.value,
        authorId: user.id,
        createdTime: time,
        modifiedTime: time,
    };
    const level = await Firestore.getLevelById(request.value.levelId);
    if (typeof level === "undefined") {
        return badRequest(`Level ${request.value.levelId} does not exist`);
    }
    const existingDraft = await Firestore.getDraftById(request.value.id);
    if (typeof existingDraft !== "undefined") {
        if (existingDraft.authorId !== user.id) {
            return conflictingId();
        }
        if (existingDraft.levelId !== request.value.levelId) {
            return badRequest(`Requested level id ${request.value} does not match existing level id ${existingDraft.levelId}`);
        }
    }
    const boardError = isBoardValid(level, request.value.board);
    if (typeof boardError !== "undefined") {
        return badRequest(boardError);
    }
    return Firestore.saveDraft(draft)
        .then(() => ok());
}

async function del(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "edit:drafts"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const request = JsonDecoder.object({
        draftId: JsonDecoder.string,
    }, "Delete draft request").decode(req.query);
    if (request instanceof Err) {
        return badRequest(request.error);
    }
    const draft = await Firestore.getDraftById(request.value.draftId);
    if (typeof draft === "undefined") {
        return ok();
    }
    if (draft.authorId !== user.id) {
        return forbidden(user.id, "delete", "draft", request.value.draftId);
    }
    return Firestore.deleteDraft(request.value.draftId)
        .then(() => ok());
}
