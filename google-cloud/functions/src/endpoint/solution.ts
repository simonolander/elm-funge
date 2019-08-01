import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import * as Firestore from "../service/firestore";
import * as Board from "../data/Board";
import * as Result from "../data/Result";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import {JsonDecoder} from "ts.data.json";
import * as Score from "../data/Score";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case 'GET':
            return get(req, res);
        case 'POST':
            return post(req, res);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`]
            }, res);
    }
}

async function get(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "read:solutions"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);

    const requestResult = decode(
        req.query,
        JsonDecoder.object(
            {
                levelId: JsonDecoder.oneOf(
                    [
                        JsonDecoder.string,
                        JsonDecoder.isUndefined(undefined)
                    ],
                    "levelId?: string"),
                campaignId: JsonDecoder.oneOf(
                    [
                        JsonDecoder.string,
                        JsonDecoder.isUndefined(undefined)
                    ],
                    "campaignId?: string")
            },
            "GetSolutionsRequest: { levelId?: string, campaignId?: string }"
        )
    );
    if (requestResult.tag === "failure") {
        return EndpointException.send(requestResult.error, res);
    }

    return Firestore.getSolutions({
        authorId: user.id,
        levelId: requestResult.value.levelId,
        campaignId: requestResult.value.levelId
    })
        .then(snapshot => res.send(snapshot.docs.map(doc => doc.data())))
}

async function post(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "submit:solutions"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);

    const solutionResult = decode(req.body, JsonDecoder.object({
        id: JsonDecoder.string,
        levelId: JsonDecoder.string,
        score: Score.decoder,
        board: Board.decoder
    }, "PostSolutionRequest"));
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


    const solutionExists = await Firestore.getSolutions({
        levelId: solution.levelId,
        authorId: user.id
    })
        .then(snapshot => {
                const boards = Result.values(snapshot.docs
                    .map(doc => doc.get('board'))
                    .map(board => decode(board, Board.decoder)));

                return boards.some(board => Board.equals(solution.board, board));
            }
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
