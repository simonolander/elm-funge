import {Request, Response} from "express";
import * as EndpointException from "../data/EndpointException";
import {verifyJwt} from "../misc/auth";
import * as Firestore from "../service/firestore"
import * as https from "https";

export async function endpoint(req: Request, res: Response): Promise<Response> {
    switch (req.method) {
        case "GET":
            return get(req, res);
        default:
            return EndpointException.send({
                status: 400,
                messages: [`Bad request method: ${req.method}`]
            }, res);
    }
}

async function getUserInfoFromAuth0(authorization: string): Promise<any> {
    return new Promise((resolve, reject) => {
        return https.get(
            {
                host: "dev-253xzd4c.eu.auth0.com",
                path: "/userinfo",
                headers: {"Authorization": authorization}
            },
            response => {
                if (response.statusCode !== 200) {
                    response.resume();
                    reject(new Error(`Bad auth0 response: ${response.statusCode}`));
                }

                response.setEncoding('utf8');
                let data = "";
                response.on("data", chunk => data += chunk);
                response.on("end", () => {
                    try {
                        resolve(JSON.parse(data))
                    }
                    catch (e) {
                        reject(e);
                    }
                });
            })
            .on("error", error => reject(error))
            .end();
    });
}

async function get(req: Request, res: Response): Promise<Response> {
    const authResult = verifyJwt(req, ["openid", "profile"]);
    if (authResult.tag === "failure") {
        return EndpointException.send(authResult.error, res);
    }
    const authorization = req.get("Authorization");
    if (typeof authorization === "undefined") {
        return EndpointException.send({status: 403, messages: ["Missing Authorization header"]}, res);
    }
    const userInfo = await getUserInfoFromAuth0(authorization);
    return Firestore.getUserBySubject(authResult.value)
        .then(ref => ref.set(userInfo, {merge: true}))
        .then(() => res.send(userInfo));
}
