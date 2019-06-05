import {Request, Response} from 'express'
import {endpoint as LevelEndpoint} from './endpoint/level'
import {endpoint as SolutionEndpoint} from './endpoint/solution'

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
export const solutions = route(SolutionsEndpoint);
export const drafts = route(DraftEndpoint);
export const userInfo = route(UserEndpoint);





exports.drafts = async (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        const subject = verifyJwt(req);

        if (req.method === 'GET') {

        } else if (req.method === 'POST') {

        } else {
            return res.status(400)
                .send({
                    status: 400,
                    messages: [`Method not allowed: ${req.method}`],
                });
        }
    } catch (error) {
        console.error(error);
        const status = error.status || 500;
        const messages = error.messages || ['An unknown error occured'];
        return res.status(status)
            .send({status, messages})
    }
};

exports.highScores = async (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        if (req.method === 'GET') {
            const {levelId} = validateObject(req.query, schemas.requestHighscore);
            const solutions = await firestore.collection("solutions")
                .where("levelId", "==", levelId)
                .get();

            const highScoreFields = ['numberOfSteps', 'numberOfInstructions'];
            const highScore = Object.entries(solutions.docs
                .map(doc => doc.data())
                .reduce((highScore, solution) => {
                    highScoreFields.forEach(field => {
                        highScore[field][solution[field]] = highScore[field][solution[field]] + 1 || 1;
                    });
                    return highScore;
                }, highScoreFields.reduce((highScore, field) => {
                    highScore[field] = {};
                    return highScore;
                }, {}))).reduce((highScore, [field, counts]) => {
                highScore[field] = Object.entries(counts)
                    .map(([key, value]) => [parseInt(key), value]);
                return highScore;
            }, {});
            highScore.levelId = levelId;

            return res.send(highScore);
        } else {
            return res.status(400)
                .send({
                    status: 400,
                    messages: [`Method not allowed: ${req.method}`],
                });
        }
    } catch (error) {
        console.error(error);
        const status = error.status || 500;
        const messages = error.messages || ['An unknown error occured'];
        return res.status(status)
            .send({status, messages})
    }
};
