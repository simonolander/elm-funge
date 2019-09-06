export function concat<T>(arrays: T[][]): T[] {
    const result: T[] = [];
    for (const array of arrays) {
        result.push(...array);
    }
    return result;
}

export function map<T1, T2>(fun: (t1: T1) => T2): (array: T1[]) => T2[] {
    return list => list.map(fun);
}
