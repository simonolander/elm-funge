import auth from "../../main/ts/misc/auth";
import * as Result from "../../main/ts/data/Result";
import * as firestore from "../../main/ts/service/firestore";
import {Solution} from "../../main/ts/data/Solution";
import {Level} from "../../main/ts/data/Level";
import * as engine from "../../main/ts/service/engine";

export const defaultTestSubject = "test-subject";
export const defaultTestUserId = "test-user-id";

export function spyVerifyJwt() {
    return jest.spyOn(auth, "verifyJwt")
        .mockReturnValue(Result.success(defaultTestSubject));
}

export function spyGetUserBySubject() {
    return jest.spyOn(firestore, "getUserBySubject")
        .mockResolvedValue({id: defaultTestUserId} as FirebaseFirestore.DocumentReference);
}

export function spyGetSolutions(value: Solution[]) {
    return jest.spyOn(firestore, "getSolutions")
        .mockResolvedValue(value);
}

export function spyGetSolutionById(value: Solution | undefined) {
    return jest.spyOn(firestore, "getSolutionById")
        .mockResolvedValue(value);
}

export function spyGetLevelById(value: Level | undefined) {
    return jest.spyOn(firestore, "getLevelById")
        .mockResolvedValue(value);
}

export function spySaveSolution() {
    return jest.spyOn(firestore, "saveSolution")
        .mockResolvedValue(undefined);
}

export function spyIsSolutionValid(value: string | undefined) {
    return jest.spyOn(engine, "isSolutionValid")
        .mockReturnValue(value);
}

export function spyConsoleWarn() {
    return jest.spyOn(console, "warn")
        .mockImplementation(() => undefined);
}
