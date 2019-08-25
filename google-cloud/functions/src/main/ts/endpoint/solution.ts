import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import {
    badRequest,
    conflictingId,
    duplicate,
    EndpointResult,
    forbidden,
    found,
    notFound,
    ok,
} from "../data/EndpointResult";
import * as Score from "../data/Score";
import * as Solution from "../data/Solution";
import {verifyJwt} from "../misc/auth";
import {decode} from "../misc/json";
import {isSolutionValid} from "../service/engine";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request): Promise<EndpointResult<any>> {
    switch (req.method) {
        case "GET":
            return get(req);
        case "POST":
            return post(req);
        default:
            return badRequest(`Bad request method: ${req.method}`);
    }
}

async function get(req: Request): Promise<EndpointResult<Solution.Solution | Solution.Solution[]>> {
    const authResult = verifyJwt<Solution.Solution>(req, ["openid", "read:solutions"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const user = await Firestore.getUserBySubject(authResult.value);

    const request = JsonDecoder.object({
            levelId: JsonDecoder.oneOf([
                    JsonDecoder.string,
                    JsonDecoder.isUndefined(undefined),
                ],
                "levelId?: string"),
            solutionId: JsonDecoder.oneOf([
                    JsonDecoder.string,
                    JsonDecoder.isUndefined(undefined),
                ],
                "solutionId?: string"),
            levelIds: JsonDecoder.oneOf([
                    JsonDecoder.string.map(levelIdString => levelIdString.split(",")),
                    JsonDecoder.isUndefined(undefined),
                ],
                "levelIds?: string[]"),
        },
        "GetSolutionsRequest",
    ).decode(req.query);

    if (request instanceof Err) {
        return badRequest(request.error);
    }

    if (typeof request.value.solutionId !== "undefined") {
        const solution = await Firestore.getSolutionById(request.value.solutionId);
        if (typeof solution === "undefined") {
            return notFound();
        }
        if (solution.authorId !== user.id) {
            return forbidden(user.id, "read", "solution", request.value.solutionId);
        }
        return found(solution);
    }

    if (typeof request.value.levelIds !== "undefined") {
        return Promise.all(request.value.levelIds.map(levelId => Firestore.getSolutions({authorId: user.id, levelId})))
            .then(solutions => solutions.reduce((acc, array) => {
                acc.push(...array);
                return acc;
            }, []))
            .then(found);
    }

    return Firestore.getSolutions({authorId: user.id, levelId: request.value.levelId})
        .then(found);
}

async function post(req: Request): Promise<EndpointResult<never>> {
    const authResult = verifyJwt<never>(req, ["openid", "submit:solutions"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const user = await Firestore.getUserBySubject(authResult.value);

    const request = decode(req.body, JsonDecoder.object({
        board: Board.decoder,
        id: JsonDecoder.string,
        levelId: JsonDecoder.string,
        score: Score.decoder,
    }, "PostSolutionRequest"));
    if (request.tag === "failure") {
        return badRequest(request.error);
    }

    const solution: Solution.Solution = {
        ...request.value,
        authorId: user.id,
        version: 1,
    };

    const existingSolution = await Firestore.getSolutionById(request.value.id);
    if (typeof existingSolution !== "undefined") {
        if (user.id !== existingSolution.authorId) {
            return conflictingId();
        }
        if (Solution.isSame(solution, existingSolution)) {
            return ok();
        }
        return conflictingId();
    }

    const level = await Firestore.getLevelById(request.value.levelId);
    if (typeof level === "undefined") {
        return badRequest(`Level ${request.value.levelId} does not exist`);
    }

    const similarSolutionExists = await Firestore.getSolutions({levelId: request.value.levelId, authorId: user.id})
        .then(solutions => solutions.some(sol => Board.equals(request.value.board, sol.board)));
    if (similarSolutionExists) {
        duplicate();
    }

    const solutionError = isSolutionValid(level, request.value.board, request.value.score);
    if (typeof solutionError !== "undefined") {
        console.warn(`645de896    Invalid solution posted by user ${user.id}`, solutionError);
        return badRequest(solutionError);
    }

    return Firestore.saveSolution(solution)
        .then(() => ok());
}
