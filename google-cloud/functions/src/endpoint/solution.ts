import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as Solution from "../data/PostSolutionRequest";
import * as Result from "../data/Result";
import * as Firestore from "../service/firestore";
import * as Board from "../data/Board";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";

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
    const scopes = ["openid", "submit:solutions"];
    const authResult = verifyJwt(req, scopes);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);

    const solutionResult = decode(req.body, Solution.decoder);
    if (solutionResult.tag === "failure") {
        return EndpointException.send(solutionResult.error, res);
    }
    const solution = solutionResult.value;

    const solutionIdExists = await Firestore.getSolutionById(solution.id)
        .then(snapshot => !snapshot.empty);
    if (solutionIdExists === true) {
        return EndpointException.send({
            status: 409,
            messages: [`Solution ${solution.id} already exists`]
        }, res);
    }

    const level = await Firestore.getLevelById(solution.levelId);
    if (level.empty) {
        return EndpointException.send({
            status: 400,
            messages: [`Level ${solution.levelId} does not exist`]
        }, res);
    }


    const solutionExists = Firestore.getSolutions({
        levelId: solution.levelId,
        authorId: user.id
    })
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
            messages: [`Author ${user.id} has already submitted a solution to this level with the same exact board`]
        }, res);
    }

    // TODO Check that solution works

    return Firestore.addSolution({...solution, authorId: user.id})
        .then(() => res.send());
}
