import {Request} from "express";
import {Err, JsonDecoder} from "ts.data.json";
import * as Board from "../data/Board";
import {
    alreadyExists,
    badRequest,
    created,
    EndpointResult,
    forbidden,
    got,
    internalServerError,
    notFound,
} from "../data/EndpointResult";
import * as Level from "../data/Level";
import * as Result from "../data/Result";
import {fromDecodeResult, values} from "../data/Result";
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

    const requestResult = decode(
        req.query,
        JsonDecoder.object(
            {
                campaignId: JsonDecoder.oneOf([
                        JsonDecoder.string,
                        JsonDecoder.isUndefined(undefined),
                    ],
                    "campaignId?: string"),
                levelId: JsonDecoder.oneOf([
                        JsonDecoder.string,
                        JsonDecoder.isUndefined(undefined),
                    ],
                    "levelId?: string"),
                solutionId: JsonDecoder.oneOf([
                    JsonDecoder.string,
                    JsonDecoder.isUndefined(undefined),
                ], "solutionId?: string"),
            },
            "GetSolutionsRequest",
        ),
    );
    if (requestResult.tag === "failure") {
        return badRequest(requestResult.error);
    }

    if (typeof requestResult.value.solutionId !== "undefined") {
        const snapshot = await Firestore.getSolutionById(requestResult.value.solutionId)
            .then(ref => ref.get());
        if (!snapshot.exists) {
            return notFound();
        }
        const solution = Solution.decoder.decode(snapshot.data());
        if (solution instanceof Err) {
            console.warn(`7b29423a    Corrupted data for solution ${requestResult.value.solutionId}`, solution.error);
            return internalServerError(`Corrupted data for solution ${requestResult.value.solutionId}`);
        }
        if (solution.value.authorId !== user.id) {
            return forbidden(user.id, "read", "solution", requestResult.value.solutionId);
        }
        return got(solution.value);
    }

    return Firestore.getSolutions({
        authorId: user.id,
        campaignId: requestResult.value.levelId,
        levelId: requestResult.value.levelId,
    })
        .then(snapshot => snapshot.docs.map(Solution.decoder.decode))
        .then(results => results.map(fromDecodeResult))
        .then(values)
        .then(got);
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

    const solutionRef = await Firestore.getSolutionById(request.value.id);
    if ((await solutionRef.get()).exists) {
        return alreadyExists();
    }

    const levelSnapshot = await Firestore.getLevelById(request.value.levelId)
        .then((ref) => ref.get());

    if (!levelSnapshot.exists) {
        return badRequest(`Level ${request.value.levelId} does not exist`);
    }

    const similarSolutionExists = await Firestore.getSolutions({levelId: request.value.levelId, authorId: user.id})
        .then((snapshot) => {
            const boards = Result.values(snapshot.docs
                .map((doc) => doc.get("board"))
                .map((board) => decode(board, Board.decoder)));

            return boards.some((board) => Board.equals(request.value.board, board));
        });
    if (similarSolutionExists) {
        alreadyExists();
    }

    const level = decode(levelSnapshot.data(), Level.decoder);

    if (level.tag === "failure") {
        console.warn(`defedda7    Corrupted data for level ${request.value.levelId}`, level.error);
        return internalServerError(`Corrupted data for level ${request.value.levelId}`);
    }

    const solutionError = isSolutionValid(level.value, request.value.board, request.value.score);
    if (typeof solutionError !== "undefined") {
        console.warn(`645de896    Invalid solution posted by user ${user.id}`, solutionError);
        return badRequest(solutionError);
    }

    const solution: Solution.Solution = {
        ...request.value,
        authorId: user.id,
    };

    return solutionRef.set(solution)
        .then(() => created());
}
