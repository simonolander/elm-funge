import {Request, Response} from "express";
import {JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import * as EndpointException from "../data/EndpointException";
import * as Result from "../data/Result";
import * as Score from "../data/Score";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case "GET":
            return get(req, res);
        case "POST":
            return post(req, res);
        default:
            return EndpointException.send({
                messages: [`Bad request method: ${req.method}`],
                status: 400,
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
                campaignId: JsonDecoder.oneOf(
                    [
                        JsonDecoder.string,
                        JsonDecoder.isUndefined(undefined),
                    ],
                    "campaignId?: string"),
                levelId: JsonDecoder.oneOf(
                    [
                        JsonDecoder.string,
                        JsonDecoder.isUndefined(undefined),
                    ],
                    "levelId?: string"),
            },
            "GetSolutionsRequest: { levelId?: string, campaignId?: string }",
        ),
    );
    if (requestResult.tag === "failure") {
        return EndpointException.send(requestResult.error, res);
    }

    return Firestore.getSolutions({
        authorId: user.id,
        campaignId: requestResult.value.levelId,
        levelId: requestResult.value.levelId,
    })
        .then((snapshot) => res.send(snapshot.docs.map((doc) => doc.data())));
}

async function post(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "submit:solutions"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const user = await Firestore.getUserBySubject(authResult.value);

    const request = decode(req.body, JsonDecoder.object({
        board: Board.decoder,
        id: JsonDecoder.string,
        levelId: JsonDecoder.string,
        score: Score.decoder,
    }, "PostSolutionRequest"));
    if (request.tag === "failure") {
        return EndpointException.send(request.error, res);
    }

    const solutionRef = await Firestore.getSolutionById(request.value.id);
    if ((await solutionRef.get()).exists) {
        return EndpointException.send({
            messages: [`Solution ${request.value.id} already exists`],
            status: 409,
        }, res);
    }

    const levelSnapshot = await Firestore.getLevelById(request.value.levelId)
        .then((ref) => ref.get());
    if (!levelSnapshot.exists) {
        return EndpointException.send({
            messages: [`Level ${request.value.levelId} does not exist`],
            status: 400,
        }, res);
    }

    const similarSolutionExists = await Firestore.getSolutions({levelId: request.value.levelId, authorId: user.id})
        .then((snapshot) => {
                const boards = Result.values(snapshot.docs
                    .map((doc) => doc.get("board"))
                    .map((board) => decode(board, Board.decoder)));

                return boards.some((board) => Board.equals(request.value.board, board));
        });
    if (similarSolutionExists) {
        return EndpointException.send({
            messages: [`Author ${user.id} has already submitted a solution to this level with the same exact board`],
            status: 409,
        }, res);
    }

    // TODO Check that solution works

    return Firestore.addSolution({...request.value, authorId: user.id})
        .then(() => res.send());
}
