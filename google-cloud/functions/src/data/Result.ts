export type Result<A, B> = Success<A> | Failure<B>;

export interface Success<A> {
    readonly tag: "success";
    readonly value: A;
}

export interface Failure<B> {
    readonly tag: "failure";
    readonly error: B;
}

export function success<A>(value: A): Success<A> {
    return {tag: "success", value};
}

export function failure<B>(error: B): Failure<B> {
    return {tag: "failure", error};
}

export function values<A, B>(results: Array<Result<A, B>>): A[] {
    const successes: A[] = [];
    const errors: B[] = [];
    for (const result of results) {
        if (result.tag === "success") {
            successes.push(result.value);
        } else {
            errors.push(result.error);
        }
    }
    if (errors.length !== 0) {
        console.warn(`321ee2b7    Found ${errors.length} errors when extracting values`, errors);
    }
    return successes;
}
