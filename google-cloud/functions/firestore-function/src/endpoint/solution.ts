import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as Solution from "../data/Solution";
import * as Result from "../data/Result";
import * as Firestore from "../service/firestore";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import * as Board from "../data/Board";
import {google} from "@google-cloud/firestore/build/protos/firestore_proto_api";
import firestore = google.firestore;

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case 'POST':
            return post(req, res);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`]
            }, res);
    }
}

async function post(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const user = Firestore.getUserBySubject(authResult.value);
    const solutionResult = decode(req.body, Solution.decoder);
    if (solutionResult.tag === "failure") {
        return EndpointException.send(solutionResult.error, res);
    }
    const solution = solutionResult.value;
    const solutionIdExists = Firestore.getSolutionById(solution.id)
        .then(solution => solution !== null);
    if (solutionIdExists) {
        return EndpointException.send({
            status: 409,
            messages: [`Solution ${solution.id} already exists`]
        }, res);
    }
    const levelExists = await firestore.collection("levels")
        .where('id', '==', solution.levelId)
        .get()
        .then(snapshot => !snapshot.empty);
    if (!levelExists) {
        return EndpointException.send({
            status: 400,
            messages: [`Level ${solution.levelId} does not exist`]
        }, res);
    }
    const solutionExists = await collection
        .where('author', '==', subject)
        .where('levelId', '==', solution.levelId)
        .select('board')
        .get()
        .then(snapshot =>
            snapshot.docs
                .map(doc => doc.get('board'))
                .map(board => decode(board, Board.decoder))
                .filter(board => board.tag === "success")
                .map(board => board as Result.Success<Board.Board>) // TODO
                .some(board => Board.equals(solution.board, board.value))
        );
    if (solutionExists) {
        return EndpointException.send({
            status: 409,
            messages: [`Author ${subject} has already submitted a solution to this level with the same exact board`]
        }, res);
    }
    return collection.add({
        ...solution,
        createdTime: new Date().getTime(),
        authorId: subject
    })
        .then(reference => reference.get())
        .then(snapshot => snapshot.data())
        .then(data => res.send(data));
}
