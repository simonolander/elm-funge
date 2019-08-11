import {Request} from "express";
import * as https from "https";

import {badRequest, EndpointResult, found, invalidAccessToken} from "../data/EndpointResult";
import {verifyJwt} from "../misc/auth";
import * as Firestore from "../service/firestore";

export async function endpoint(req: Request): Promise<EndpointResult<any>> {
    switch (req.method) {
        case "GET":
            return get(req);
        default:
            return badRequest(`Bad request method: ${req.method}`);
    }
}

async function getUserInfoFromAuth0(authorization: string): Promise<any> {
    return new Promise((resolve, reject) => {
        return https.get(
            {
                host: "dev-253xzd4c.eu.auth0.com",
                path: "/userinfo",
                headers: {Authorization: authorization},
            },
            response => {
                if (response.statusCode !== 200) {
                    response.resume();
                    reject(new Error(`Bad auth0 response: ${response.statusCode}`));
                }

                response.setEncoding("utf8");
                let data = "";
                response.on("data", chunk => data += chunk);
                response.on("end", () => {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .on("error", error => reject(error))
            .end();
    });
}

async function get(req: Request): Promise<EndpointResult<any>> {
    const authResult = verifyJwt(req, ["openid", "profile"]);
    if (authResult.tag === "failure") {
        return authResult.error;
    }
    const authorization = req.get("Authorization");
    if (typeof authorization === "undefined") {
        return invalidAccessToken(["Missing Authorization header"]);
    }
    const userInfo = await getUserInfoFromAuth0(authorization);
    return Firestore.getUserBySubject(authResult.value)
        .then(ref => ref.set(userInfo, {merge: true}))
        .then(() => found(userInfo));
}
