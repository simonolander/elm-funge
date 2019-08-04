import {Request, Response} from "express";
import {EndpointResult, getBody, getStatusCode, internalServerError} from "./data/EndpointResult";
import {endpoint as DraftEndpoint} from "./endpoint/draft";
import {endpoint as HighScoreEndpoint} from "./endpoint/highScore";
import {endpoint as LevelEndpoint} from "./endpoint/level";
import {endpoint as SolutionEndpoint} from "./endpoint/solution";
import {endpoint as UserEndpoint} from "./endpoint/user";

async function route(req: Request, res: Response, endpoint: (req: Request, res: Response) => Promise<EndpointResult<any>>) {
    try {
        res.set("Access-Control-Allow-Origin", "*");
        if (req.method === "OPTIONS") {
            res.set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
            res.set("Access-Control-Max-Age", "3600");
            return res.status(204).send();
        } else {
            return endpoint(req, res)
                .then(result => res.status(getStatusCode(result))
                    .send(getBody(result)));
        }
    } catch (error) {
        console.error(error);
        if (error instanceof Error) {
            const result = internalServerError([
                `Unexpected ${error.name} error occured when performing the request`,
                error.message,
            ]);
            return res.status(getStatusCode(result))
                .send(getBody(result));
        } else {
            const result = internalServerError(`An unexpected error occured when performing the request`);
            return res.status(getStatusCode(result))
                .send(getBody(result));
        }
    }
}

export async function levels(req: Request, res: Response) {
    return route(req, res, LevelEndpoint);
}

export async function solutions(req: Request, res: Response) {
    return route(req, res, SolutionEndpoint);
}

export async function drafts(req: Request, res: Response) {
    return route(req, res, DraftEndpoint);
}

export async function userInfo(req: Request, res: Response) {
    return route(req, res, UserEndpoint);
}

export async function highScores(req: Request, res: Response) {
    return route(req, res, HighScoreEndpoint);
}
