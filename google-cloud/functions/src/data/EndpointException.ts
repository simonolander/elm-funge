import { Response } from "express";

export interface EndpointException {
    status: number;
    messages: string[];
}

export function send(exception: EndpointException, res: Response): Response {
    return res.status(exception.status)
        .send({
            status: exception.status,
            messages: exception.messages,
        });
}
