export type Result<A, B> = Success<A> | Failure<B>

export interface Success<A> {
    readonly tag: "success",
    readonly value: A
}

export interface Failure<B> {
    readonly tag: "failure",
    readonly error: B
}

export function success<A>(value: A): Success<A> {
    return {tag: "success", value: value}
}

export function failure<B>(error: B): Failure<B> {
    return {tag: "failure", error: error};
}
