import {Request, Response} from 'express'
import {endpoint as LevelEndpoint} from './endpoint/level'
import {endpoint as SolutionEndpoint} from './endpoint/solution'
import {endpoint as DraftEndpoint} from './endpoint/draft'
import {endpoint as UserEndpoint} from './endpoint/user'
import {endpoint as HighScoreEndpoint} from './endpoint/highScore'

async function route(endpoint: (req: Request, res: Response) => Promise<Response>) {
    return async function (req: Request, res: Response): Promise<Response> {
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
}

export const levels = route(LevelEndpoint);
export const solutions = route(SolutionEndpoint);
export const drafts = route(DraftEndpoint);
export const userInfo = route(UserEndpoint);
export const highScores = route(HighScoreEndpoint);

