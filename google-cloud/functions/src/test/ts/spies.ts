import {Draft} from "../../main/ts/data/Draft";
import {Level} from "../../main/ts/data/Level";
import * as Result from "../../main/ts/data/Result";
import {Solution} from "../../main/ts/data/Solution";
import * as auth from "../../main/ts/misc/auth";
import * as engine from "../../main/ts/service/engine";
import * as firestore from "../../main/ts/service/firestore";

export const defaultTestSubject = "test-subject";
export const defaultTestUserId = "test-user-id";
export const notTestUserId = `not-${defaultTestUserId}`;

export function verifyJwt(value: Result.Result<string, any> = Result.success(defaultTestSubject)) {
    return jest.spyOn(auth, "verifyJwt")
        .mockReturnValue(value);
}

export function getUserBySubject() {
    return jest.spyOn(firestore, "getUserBySubject")
        .mockResolvedValue({id: defaultTestUserId} as FirebaseFirestore.DocumentReference);
}

export function getSolutions(value: Solution[]) {
    return jest.spyOn(firestore, "getSolutions")
        .mockResolvedValue(value);
}

export function getSolutionById(value: Solution | undefined) {
    return jest.spyOn(firestore, "getSolutionById")
        .mockResolvedValue(value);
}

export function getLevelById(value: Level | undefined) {
    return jest.spyOn(firestore, "getLevelById")
        .mockResolvedValue(value);
}

export function saveSolution() {
    return jest.spyOn(firestore, "saveSolution")
        .mockResolvedValue(undefined);
}

export function isSolutionValid(value: string | undefined) {
    return jest.spyOn(engine, "isSolutionValid")
        .mockReturnValue(value);
}

export function consoleWarn() {
    return jest.spyOn(console, "warn")
        .mockImplementation(() => undefined);
}

export function getDrafts(value: Draft[] | ((params: {levelId?: string, authorId?: string, draftId?: string}) => Draft[]) = []) {
    if (typeof value === "function") {
        return jest.spyOn(firestore, "getDrafts")
            .mockImplementation(params => Promise.resolve(value(params)));
    }
    return jest.spyOn(firestore, "getDrafts")
        .mockResolvedValue(value);
}

export function getDraftById(value?: Draft) {
    return jest.spyOn(firestore, "getDraftById")
        .mockResolvedValue(value);
}
