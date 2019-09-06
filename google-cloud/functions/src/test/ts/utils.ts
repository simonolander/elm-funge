export function range(end: number): number[] {
    const list: number[] = [];
    if (end <= 0 || !isFinite(end)) {
        return list;
    }
    for (let n = 0; n < end; ++n) {
        list.push(n);
    }
    return list;
}

export function shuffle<T>(list: T[]): T[] {
    const copy = [...list];
    for (let i = copy.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
}

export function contains<T>(needle: T, haystack: T[]): boolean {
    return haystack.indexOf(needle) !== -1;
}

export function randomInteger(ceiling: number): number {
    if (!isFinite(ceiling) || ceiling <= 0) {
        throw new Error();
    }
    return Math.floor(Math.random() * ceiling);
}

export function randomId(): string {
    const chars = "abcdef0123456789";
    return range(16)
        .map(() => chars.charAt(randomInteger(chars.length)))
        .join("");
}

export function chooseOne<T>(list: T[]): T {
    if (list.length === 0) {
        throw new Error("cannot choose an element from an empty list");
    }
    return list[randomInteger(list.length)];
}

export function chooseN<T>(n: number, list: T[]): T[] {
    if (list.length < n) {
        throw Error();
    }
    if (list.length === 0) {
        return [];
    }
    return shuffle(list).slice(0, n);
}

export function expectArraySameContent<T>(actual: T[], expected: T[]): void {
    expect(Array.isArray(actual)).toEqual(true);
    expect(actual).toHaveLength(expected.length);
    for (const e of expected) {
        expect(actual).toContainEqual(e);
    }
    for (const a of actual) {
        expect(expected).toContainEqual(a);
    }
}
