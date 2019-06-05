import {Request, Response} from 'express';
import * as EndpointException from "../data/EndpointException";
import {verifyJwt} from "../misc/auth";
import * as Firestore from '../service/firestore'

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case 'GET':
            return get(req, res);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`]
            }, res);
    }
}

async function get(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const subject = authResult.value;
    return Firestore.getUserBySubject(subject)
        .then(user => res.send(user.data()))
}
