import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as PostDraftRequest from "../data/PostDraftRequest";
import {verifyJwt} from "../misc/auth";
import * as Firestore from '../service/firestore'
import {decode} from "../misc/json";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case 'GET':
            return get(req, res);
        case 'POST':
            return post(req, res,);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`]
            }, res);
    }
}

async function get(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const subject = authResult.value;
    return Firestore.getUserBySubject(subject)
        .then(ref => Firestore.getDrafts({authorId: ref.id}))
        .then(ref => ref.docs.map(doc => doc.data()))
        .then(data => res.send(data));
}

async function post(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);
    const draftResult = decode(req.body, PostDraftRequest.decoder);
    if (draftResult.tag === "failure") {
        return EndpointException.send(draftResult.error, res);
    }
    const draftRequest = draftResult.value;
    const levelExists = await Firestore.getLevelById(draftRequest.levelId)
        .then(snapshot => !snapshot.empty);
    if (levelExists === false) {
        return EndpointException.send({
            status: 404,
            messages: [`Level ${draftRequest.levelId} does not exist`]
        }, res);
    }
    const existingDraft = await Firestore.getDraftById(draftRequest.id);
    if (existingDraft.empty) {
        const time = new Date().getTime();
        const draft = {
            ...draftResult.value,
            authorId: user.id,
            createdTime: time,
            modifiedTime: time
        };
        return Firestore.addDraft(draft)
            .then(ref => ref.get())
            .then(ref => res.send(ref.data()));
    } else {
        if (existingDraft.docs[0].get('authorId') !== user.id) {
            return EndpointException.send({
                status: 403,
                messages: [`User ${user.id} does not have permission to edit draft ${draftRequest.id}`]
            }, res)
        }
        let existingLevelId = existingDraft.docs[0].get('levelId');
        if (existingLevelId !== draftRequest.levelId) {
            return EndpointException.send({
                status: 400,
                messages: [`Requested level id ${draftRequest} does not match existing level id ${existingLevelId}`]
            }, res)
        }
        Firestore.getDraftDocument(existingDraft.docs[0].id)
            .then(ref => ref.set({
                board: draftRequest.board
            }, {merge: true}))
            .then(() => res.send());
    }
}
