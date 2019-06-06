import {Request, Response} from 'express'
import {endpoint as LevelEndpoint} from './endpoint/level'
import {endpoint as SolutionEndpoint} from './endpoint/solution'
import {endpoint as DraftEndpoint} from './endpoint/draft'
import {endpoint as UserEndpoint} from './endpoint/user'
import {endpoint as HighScoreEndpoint} from './endpoint/highScore'

async function route(req: Request, res: Response, endpoint: (req: Request, res: Response) => Promise<Response>) {
    try {
        res.set('Access-Control-Allow-Origin', '*');
        if (req.method === 'OPTIONS') {
            res.set('Access-Control-Allow-Methods', 'GET');
            res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
            res.set('Access-Control-Max-Age', '3600');
            return res.status(204).send('');
        } else {
            return endpoint(req, res)
        }
    } catch (error) {
        console.error(error);
        return res.status(500)
            .send({
                status: 500,
                messages: ["An error occured when performing the request"],
                error: error
            })
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


