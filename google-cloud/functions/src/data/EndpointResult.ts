import {Collection} from "../service/firestore";

export type EndpointResult<T> =
    Got<T>
    | Created
    | Updated
    | Deleted
    | NotFound
    | BadRequest
    | InvalidAccessToken
    | Forbidden
    | AlreadyExists
    | AlreadyDeleted
    | InternalServerError;

interface Got<T> {
    tag: "Got";
    body: T;
}

interface Created {
    tag: "Created";
}

interface Updated {
    tag: "Updated";
}

interface Deleted {
    tag: "Deleted";
}

interface NotFound {
    tag: "NotFound";
}

interface BadRequest {
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

interface AlreadyExists {
    tag: "AlreadyExists";
}

interface AlreadyDeleted {
    tag: "AlreadyDeleted";
}

interface InternalServerError {
    tag: "InternalServerError";
    messages: string[];
}

export function getStatusCode<T>(result: EndpointResult<T>): number {
    switch (result.tag) {
        case "Got":
            return 200;
        case "Created":
            return 200;
        case "Updated":
            return 200;
        case "Deleted":
            return 200;
        case "NotFound":
            return 404;
        case "BadRequest":
            return 400;
        case "InvalidAccessToken":
            return 403;
        case "Forbidden":
            return 403;
        case "AlreadyExists":
            return 409;
        case "AlreadyDeleted":
            return 200;
        case "InternalServerError":
            return 500;
    }
}

export function getBody<T>(result: EndpointResult<T>): T | EndpointResult<T> {
    switch (result.tag) {
        case "Got":
            return result.body;
        default:
            return result;
    }
}

export function got<T>(body: T): EndpointResult<T> {
    return {
        tag: "Got",
        body,
    };
}

export function created<T>(): EndpointResult<T> {
    return {
        tag: "Created",
    };
}

export function updated<T>(): EndpointResult<T> {
    return {
        tag: "Updated",
    };
}

export function deleted<T>(): EndpointResult<T> {
    return {
        tag: "Deleted",
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

export function alreadyExists<T>(): EndpointResult<T> {
    return {
        tag: "AlreadyExists",
    };
}

export function alreadyDeleted<T>(): EndpointResult<T> {
    return {
        tag: "AlreadyDeleted",
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
