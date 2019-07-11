import {Request} from "express";
import * as Result from "../data/Result";
import {EndpointException} from "../data/EndpointException";
import {JsonWebTokenError, NotBeforeError, TokenExpiredError, verify} from "jsonwebtoken";

// const AMAZON_COGNITO_PEM =
//     `-----BEGIN PUBLIC KEY-----
// MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnw9jJN1VszovM0H9M0SA
// QB2MvXCGRsdz0WaApl5VYOrCrXOcHsvDzZ4CDup+NJvRMLFbLK8fUMqrZPnY5Qnp
// keF6ZSiX+axHF8531+puvsDeDyYOeX/Ysjaftw5aq9bHcSkEbH5zqKWifClfbFvO
// 0cS/bY9T5+astotPH8n87KMG/KMcZOVtOcOhYusb/oIrct40t3z18VfPB+kMQtUK
// 4ekt0yf1J543kAY+nBjkyie9/bMyBhjGXJZcly4fRimhatrUgSn/S4BWgPyIzVWP
// 6ywgwfDPVQzVgyWQrz5tSLRX5dPLe2zZYkdnTVFWBxynebpg5ZPUoQk+J08/lPLy
// 0wIDAQAB
// -----END PUBLIC KEY-----`;
// const AMAZON_COGNITO_AUD = '1mu4rr1moo02tobp2m4oe80pn8';
// const AMAZON_COGNITO_ISS = 'https://cognito-idp.us-east-1.amazonaws.com/us-east-1_BbVWFzVcU';

const AUTH0_PEM =
    `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5p0770GvIbSHccc1p02i
JSOX3qzora1iNRJJOooyvEjAmHZeRbiZlsaw86YvEcM9dllK9rVpj3TTE1E5MGJz
U3p7DzIBTfHE4f3K1gBlKiWuo/mUClEu5XRnPL36brfRfaRHe42rjzPFoZyjGZN4
QU4cqa13eQsTPRb+6OOYPiUPHhnTlfxr/0eGf4E8j3PQmsiCzjpQJkdgG2Kb8thH
iAdQvWb9plN5brxB4+7HXOVs+KqKRCrAVRJ6x4YggNFDjOxcSyvylpDZGY+OnRpI
/V1OD62pjU8pOzwE+TA3DBpdbmB+/EpINDotQ4R0LCXWwq04b/x7LwSouR09iMhF
+wIDAQAB
-----END PUBLIC KEY-----`;
const AUTH0_AUD = 'https://us-central1-luminous-cubist-234816.cloudfunctions.net';
const AUTH0_ISS = 'https://dev-253xzd4c.eu.auth0.com/';

const audience = AUTH0_AUD;
const issuer = AUTH0_ISS;
const pem = AUTH0_PEM;

export function verifyJwt(req: Request, scopes: string[]): Result.Result<string, EndpointException> {
    try {
        const authorizationHeader = req.get('Authorization');
        if (typeof authorizationHeader !== 'string') {
            return Result.failure({
                status: 403,
                messages: [`Failed failed to extract authorization header, malformed header: ${authorizationHeader}`]
            });
        }
        const splits = authorizationHeader.split(' ');
        if (splits.length !== 2) {
            return Result.failure({
                status: 403,
                messages: [`Failed failed to extract authorization header, malformed header: ${authorizationHeader}`]
            });
        }
        const [type, token] = splits;
        if (type !== 'Bearer') {
            return Result.failure({
                status: 403,
                messages: [`Failed failed to extract authorization header, invalid type: ${type}`]
            });
        }
        const tokenObject: any = verify(token, pem, {
            algorithms: ['RS256'],
            audience: audience,
            issuer: issuer
        });
        if (typeof tokenObject !== 'object') {
            return Result.failure({
                status: 403,
                messages: [`Failed to verify jwt, invalid tokenObject: ${typeof tokenObject}`]
            });
        }
        const subject = tokenObject["sub"];
        if (typeof subject !== 'string') {
            return Result.failure({
                status: 403,
                messages: [`Failed to verify jwt, invalid subject: ${subject}`]
            });
        }
        if (subject.length === 0) {
            return Result.failure({
                status: 403,
                messages: [`Failed to verify jwt, subject is empty`]
            });
        }
        const scope = tokenObject["scope"];
        if (typeof scope !== "string") {
            return Result.failure({
                status: 403,
                messages: [`Failed to verify jwt, malformed scope: ${typeof scope}`]
            });
        }
        const presentScopes = scope.split(" ");
        const missingScopes = scopes.filter(scope => presentScopes.indexOf(scope) === -1);
        if (missingScopes.length !== 0) {
            return Result.failure({
                status: 403,
                messages: missingScopes.map(scope => `Failed to verify jwt, missing scope: ${scope}`)
            });
        }
        return Result.success(subject);
    } catch (e) {
        if (e instanceof TokenExpiredError) {
            return Result.failure({
                status: 403,
                messages: [
                    `Token expired at ${e.expiredAt.toISOString()}`,
                    e.message
                ]
            });
        } else if (e instanceof NotBeforeError) {
            return Result.failure({
                status: 403,
                messages: [
                    `Token is not valid before ${e.date.toISOString()}`,
                    e.message
                ]
            });

        } else if (e instanceof JsonWebTokenError) {
            return Result.failure({
                status: 403,
                messages: [
                    `There was an error with the token`,
                    e.message
                ]
            });
        } else {
            throw e;
        }
    }
}
