import {Collection} from "../service/firestore";

export type EndpointResult<T> =
    Found<T>
    | Ok
    | NotFound
    | BadRequest
    | InvalidAccessToken
    | Forbidden
    | ConflictingId
    | Duplicate
    | InternalServerError;

export interface Found<T> {
    tag: "Found";
    body: T;
}

interface Ok {
    tag: "Ok";
}

interface NotFound {
    tag: "NotFound";
}

export interface BadRequest {
    tag: "BadRequest";
    messages: string[];
}

interface InvalidAccessToken {
    tag: "InvalidAccessToken";
    messages: string[];
}

interface Forbidden {
    tag: "Forbidden";
    messages: string[];
}

interface ConflictingId {
    tag: "ConflictingId";
}

interface InternalServerError {
    tag: "InternalServerError";
    messages: string[];
}

interface Duplicate {
    tag: "Duplicate";
}

export function getStatusCode<T>(result: EndpointResult<T>): number {
    switch (result.tag) {
        case "Ok":
            return 200;
        case "ConflictingId":
            return 409;
        case "Duplicate":
            return 409;
        case "Found":
            return 200;
        case "NotFound":
            return 404;
        case "BadRequest":
            return 400;
        case "InvalidAccessToken":
            return 403;
        case "Forbidden":
            return 403;
        case "InternalServerError":
            return 500;
    }
}

export function getBody<T>(result: EndpointResult<T>): T | EndpointResult<T> {
    switch (result.tag) {
        case "Found":
            return result.body;
        default:
            return result;
    }
}

export function found<T>(body: T): EndpointResult<T> {
    return {
        tag: "Found",
        body,
    };
}

export function ok<T>(): EndpointResult<T> {
    return {
        tag: "Ok",
    };
}

export function notFound<T>(): EndpointResult<T> {
    return {
        tag: "NotFound",
    };
}

export function badRequest<T>(messages: string | string[]): EndpointResult<T> {
    return {
        tag: "BadRequest",
        messages: typeof messages === "string"
            ? [messages]
            : messages,
    };
}

export function invalidAccessToken<T>(messages: string[]): EndpointResult<T> {
    return {
        tag: "InvalidAccessToken",
        messages,
    };
}

export function forbidden<T>(userId: string, action: "read" | "edit" | "delete" | "publish", type: "draft" | "blueprint" | "solution", resourceId: string): EndpointResult<T> {
    return {
        tag: "Forbidden",
        messages: [`User ${userId} does not have permission to ${action} ${type} ${resourceId}`],
    };
}

export function internalServerError<T>(message: string | string[]): EndpointResult<T> {
    return {
        tag: "InternalServerError",
        messages: typeof message === "string" ? [message] : message,
    };
}

export function corruptData<T>(collection: Collection, id: string, error: string): EndpointResult<T> {
    console.warn(`1dbe7429    Corrupted data in ${collection} for id ${id}`, error);
    return internalServerError(`Corrupted data in ${collection} for id ${id}`);
}

export function conflictingId<T>(): EndpointResult<T> {
    return {
        tag: "ConflictingId",
    };
}

export function duplicate<T>(): EndpointResult<T> {
    return {
        tag: "Duplicate",
    };
}
