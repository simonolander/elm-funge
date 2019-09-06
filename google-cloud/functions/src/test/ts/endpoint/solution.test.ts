import {Request} from "express";
import {Board} from "../../../main/ts/data/Board";
import {BadRequest, EndpointResult, Found, invalidAccessToken} from "../../../main/ts/data/EndpointResult";
import {Level} from "../../../main/ts/data/Level";
import * as Result from "../../../main/ts/data/Result";
import {Score} from "../../../main/ts/data/Score";
import {Solution} from "../../../main/ts/data/Solution";
import * as solutionEndpoint from "../../../main/ts/endpoint/solution";
import auth from "../../../main/ts/misc/auth";
import * as engine from "../../../main/ts/service/engine";
import * as firestore from "../../../main/ts/service/firestore";
import {chooseN, chooseOne, contains, expectArraySameContent, randomId, range} from "../utils";

jest.mock("../../../main/ts/service/firestore");

const testSubject = "test-subject";
const testUserId = "test-user-id";

describe("solution endpoint", () => {
    function spyVerifyJwt() {
        return jest.spyOn(auth, "verifyJwt")
            .mockReturnValue(Result.success(testSubject));
    }

    function spyGetUserBySubject() {
        return jest.spyOn(firestore, "getUserBySubject")
            .mockResolvedValue({id: testUserId} as FirebaseFirestore.DocumentReference);
    }

    function spyGetSolutions(value: Solution[]) {
        return jest.spyOn(firestore, "getSolutions")
            .mockResolvedValue(value);
    }

    function spyGetSolutionById(value: Solution | undefined) {
        return jest.spyOn(firestore, "getSolutionById")
            .mockResolvedValue(value);
    }

    function spyGetLevelById(value: Level | undefined) {
        return jest.spyOn(firestore, "getLevelById")
            .mockResolvedValue(value);
    }

    function spySaveSolution() {
        return jest.spyOn(firestore, "saveSolution")
            .mockResolvedValue(undefined);
    }

    function spyIsSolutionValid(value: string | undefined) {
        return jest.spyOn(engine, "isSolutionValid")
            .mockReturnValue(value);
    }

    function spyConsoleWarn() {
        return jest.spyOn(console, "warn")
            .mockImplementation(() => undefined);
    }

    describe("get", () => {
        async function get(params: { levelId?: string, solutionId?: string, levelIds?: string }): Promise<EndpointResult<Solution | Solution[]>> {
            return solutionEndpoint.endpoint({method: "GET", query: params} as Request);
        }

        test("should return forbidden if verifyJwt fails", () => {
            const message = "4bf174096ed37be1";
            const verifyJwtSpy = jest.spyOn(auth, "verifyJwt")
                .mockReturnValue(Result.failure(invalidAccessToken([message])));
            return get({})
                .then(value => {
                    expect(value).toEqual({tag: "InvalidAccessToken", messages: [message]});
                    expect(verifyJwtSpy).toHaveBeenCalled();
                });
        });

        test("should retrieve an empty list when database is empty", () => {
            const verifyJwtSpy = spyVerifyJwt();
            const getSolutionsSpy = spyGetSolutions([]);
            const getUserBySubjectSpy = spyGetUserBySubject();
            return get({})
                .then(value => {
                    expect(value).toEqual({tag: "Found", body: []});
                    expect(verifyJwtSpy).toHaveBeenCalled();
                    expect(getSolutionsSpy).toHaveBeenCalledWith({authorId: testUserId});
                    expect(getUserBySubjectSpy).toHaveBeenCalledWith(testSubject);
                });
        });

        describe("get solution by solution id", () => {
            const solutionId = "51b4aa0e9b0ceef5";
            test("should retrieve the the solution if database has it", () => {
                const solution = {
                    id: solutionId,
                    authorId: testUserId,
                } as Solution;
                const verifyJwtSpy = spyVerifyJwt();
                const getSolutionByIdSpy = spyGetSolutionById(solution);
                const getUserBySubjectSpy = spyGetUserBySubject();
                return get({solutionId})
                    .then(value => {
                        expect(value).toEqual({tag: "Found", body: solution});
                        expect(verifyJwtSpy).toHaveBeenCalled();
                        expect(getSolutionByIdSpy).toHaveBeenCalledWith(solutionId);
                        expect(getUserBySubjectSpy).toHaveBeenCalledWith(testSubject);
                    });
            });

            test("should return forbidden if requesting solution that you don't own", () => {
                const solution = {
                    id: solutionId,
                    authorId: `not-${testUserId}`,
                } as Solution;
                const verifyJwtSpy = spyVerifyJwt();
                const getSolutionByIdSpy = spyGetSolutionById(solution);
                const getUserBySubjectSpy = spyGetUserBySubject();
                return get({solutionId})
                    .then(value => {
                        expect(value).toEqual({
                            tag: "Forbidden",
                            messages: [`User ${testUserId} does not have permission to read solution ${solution.id}`],
                        });
                        expect(verifyJwtSpy).toHaveBeenCalled();
                        expect(getSolutionByIdSpy).toHaveBeenCalledWith(solutionId);
                        expect(getUserBySubjectSpy).toHaveBeenCalledWith(testSubject);
                    });
            });

            test("should return not found if the database doesn't have the solution", () => {
                const verifyJwtSpy = spyVerifyJwt();
                const getSolutionByIdSpy = spyGetSolutionById(undefined);
                const getUserBySubjectSpy = spyGetUserBySubject();
                return get({solutionId})
                    .then(value => {
                        expect(value).toEqual({tag: "NotFound"});
                        expect(verifyJwtSpy).toHaveBeenCalled();
                        expect(getSolutionByIdSpy).toHaveBeenCalledWith(solutionId);
                        expect(getUserBySubjectSpy).toHaveBeenCalledWith(testSubject);
                    });
            });
        });

        describe("bad requests", () => {
            test("should return bad request if levelId is not a string", () => {
                spyVerifyJwt();
                return get({levelId: 3} as {})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toMatch(/\blevelId\b/);
                    });
            });

            test("should return bad request if solutionId is not a string", () => {
                spyVerifyJwt();
                return get({solutionId: new Date()} as {})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toMatch(/\bsolutionId\b/);
                    });
            });

            test("should return bad request if levelIds is not a string", () => {
                spyVerifyJwt();
                return get({levelIds: () => 3} as {})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toMatch(/\blevelIds\b/);
                    });
            });
        });

        describe("get solution by level id", () => {
            const levelId = "0049119831de9cd6";
            test("should call firestore with the id and return its solutions", () => {
                const solutions = [
                    {
                        id: "c9f03b3b3420ea9a",
                        authorId: `${testUserId}`,
                    },
                    {
                        id: "705ff9777e72aa84",
                        authorId: `${testUserId}`,
                    },
                    {
                        id: "4fa7a3547674542b",
                        authorId: `${testUserId}`,
                    },
                ] as Solution[];
                spyVerifyJwt();
                const getSolutionsSpy = jest.spyOn(firestore, "getSolutions")
                    .mockResolvedValue(solutions);
                spyGetUserBySubject();
                return get({levelId})
                    .then(value => {
                        expect(value).toEqual({
                            tag: "Found",
                            body: solutions,
                        });
                        expect(getSolutionsSpy).toHaveBeenCalledWith({levelId, authorId: testUserId});
                    });
            });
        });

        describe("get solution by level ids", () => {
            test("should get all solutions with matching level ids", () => {
                const levelIds = range(10).map(randomId);
                const authorIds = [testUserId, `not-${testUserId}`];
                const solutions =
                    range(100)
                        .map(() => ({
                            id: randomId(),
                            levelId: chooseOne(levelIds),
                            authorId: chooseOne(authorIds),
                        })) as Solution[];
                const chosenLevelIds = chooseN(5, levelIds);
                spyVerifyJwt();
                const spy = jest.spyOn(firestore, "getSolutions")
                    .mockImplementation(({levelId, authorId}) =>
                        Promise.resolve(solutions.filter(solution =>
                            solution.levelId === levelId && solution.authorId === authorId)));
                spyGetUserBySubject();
                return get({levelIds: chosenLevelIds.join(",")})
                    .then(value => {
                        expect(value.tag).toEqual("Found");
                        const expectedSolutions = solutions.filter(({authorId, levelId}) => authorId === testUserId && contains(levelId, chosenLevelIds));
                        expectArraySameContent((value as Found<Solution[]>).body, expectedSolutions);
                        expect(spy).toHaveBeenCalledTimes(chosenLevelIds.length);
                    });
            });
        });
    });

    describe("post", () => {
        async function post(params: {
            id: string,
            levelId: string,
            board: Board,
            score: Score,
        }): Promise<EndpointResult<Solution | Solution[]>> {
            return solutionEndpoint.endpoint({method: "POST", body: params} as Request);
        }

        const solution = {
            version: 1,
            id: "b4613392fcdff3e6",
            levelId: "4ffebe95707abd7d",
            score: {
                numberOfSteps: 10,
                    numberOfInstructions: 20,
            },
            board: {
                width: 4,
                    height: 4,
                    instructions: [],
            },
            authorId: testUserId,
        };

        const body = {
            id: solution.id,
            levelId: solution.levelId,
            board: solution.board,
            score: solution.score,
        };

        describe("bad jwt token", () => {
            test("should fail if jwt verifier fails", () => {
                const messages = ["51574963486dd5d0"];
                const verifyJwtSpy = jest.spyOn(auth, "verifyJwt")
                    .mockReturnValue(Result.failure(invalidAccessToken(messages)));
                const saveSolutionSpy = spySaveSolution();
                return post(body)
                    .then(value => {
                        expect(value).toEqual({tag: "InvalidAccessToken", messages});
                        expect(verifyJwtSpy).toHaveBeenCalled();
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });
        });

        describe("bad request", () => {
            test("should return bad request if board is not a valid board", () => {
                spyVerifyJwt();
                spyGetUserBySubject();
                const saveSolutionSpy = spySaveSolution();
                return post({...body, board: {} as Board})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toMatch(/\bboard\b/);
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });

            test("should return bad request if id is not a string", () => {
                spyVerifyJwt();
                spyGetUserBySubject();
                const saveSolutionSpy = spySaveSolution();
                return post({...body, id: {} as string})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toMatch(/\bid\b/);
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });

            });

            test("should return bad request if levelId is not a string", () => {
                spyVerifyJwt();
                spyGetUserBySubject();
                const saveSolutionSpy = spySaveSolution();
                return post({...body, levelId: {} as string})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toMatch(/\blevelId\b/);
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });

            });

            test("should return bad request if score is not a valid score", () => {
                spyVerifyJwt();
                spyGetUserBySubject();
                const saveSolutionSpy = spySaveSolution();
                return post({...body, score: {} as Score})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toMatch(/\bscore\b/);
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });

            test("should return bad request if level doesn't exist", () => {
                spyVerifyJwt();
                spyGetUserBySubject();
                spyGetLevelById(undefined);
                const saveSolutionSpy = spySaveSolution();
                return post({...body})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toMatch(body.levelId);
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });

            test("should return bad request if the solution is invalid", () => {
                const message = "some message about invalid solution";
                spyVerifyJwt();
                spyGetUserBySubject();
                spyGetLevelById({} as Level);
                spyGetSolutions([]);
                const isSolutionValid = spyIsSolutionValid(message);
                const consoleWarnSpy = spyConsoleWarn();
                const saveSolutionSpy = spySaveSolution();
                return post({...body})
                    .then(value => {
                        expect(value.tag).toEqual("BadRequest");
                        expect((value as BadRequest).messages[0]).toEqual(message);
                        expect(consoleWarnSpy).toHaveBeenCalled();
                        expect(isSolutionValid).toHaveBeenCalled();
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });
        });

        describe("solution with same id or board exists", () => {
            test("should return conflicting id if there exists a solution with the same id from another user", () => {
                const otherSolution = {...solution, authorId: `not-${testUserId}`};
                spyVerifyJwt();
                spyGetUserBySubject();
                spyGetSolutionById(otherSolution);
                const saveSolutionSpy = spySaveSolution();
                return post(body)
                    .then(value => {
                        expect(value.tag).toEqual("ConflictingId");
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });

            test("should return conflicting id if there exists a different solution with the same id from this user", () => {
                const otherSolution = {
                    ...solution,
                    board: {...body.board, height: body.board.height + 1},
                };
                spyVerifyJwt();
                spyGetUserBySubject();
                spyGetSolutionById(otherSolution);
                const saveSolutionSpy = spySaveSolution();
                return post(body)
                    .then(value => {
                        expect(value.tag).toEqual("ConflictingId");
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });

            test("should return ok if there exists the same solution with the same id from this user", () => {
                const otherSolution = {...solution};
                spyVerifyJwt();
                spyGetUserBySubject();
                spyGetSolutionById(otherSolution);
                const saveSolutionSpy = spySaveSolution();
                return post(body)
                    .then(value => {
                        expect(value.tag).toEqual("Ok");
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });

            test("should return duplicate if there exists a solution with different id but same board from this user", () => {
                const otherSolutions = [{...solution, id: "f36d59076ea308f8"}];
                spyVerifyJwt();
                spyGetUserBySubject();
                spyGetSolutionById(undefined);
                spyGetSolutions(otherSolutions);
                spyGetLevelById({} as Level);
                spyIsSolutionValid(undefined);
                const saveSolutionSpy = spySaveSolution();
                return post(body)
                    .then(value => {
                        expect(value).toEqual({tag: "Duplicate"});
                        expect(saveSolutionSpy).not.toHaveBeenCalled();
                    });
            });
        });

        describe("happy case", () => {
            test("should return ok if solution is valid and it doesn't already exist in some way", () => {
                spyVerifyJwt();
                spyGetUserBySubject();
                spyGetSolutionById(undefined);
                spyGetSolutions([]);
                spyGetLevelById({} as Level);
                spyIsSolutionValid(undefined);
                spySaveSolution();
                const saveSolutionSpy = spySaveSolution();
                return post(body)
                    .then(value => {
                        expect(value).toEqual({tag: "Ok"});
                        expect(saveSolutionSpy).toHaveBeenCalled();
                    });
            });

            test("should return ok if solution is valid and it doesn't already exist in some way and there are other solutions", () => {
                const otherSolutions = [
                    {...solution, board: {...solution.board, id: "3fb139c74934d45d", height: solution.board.height - 1}},
                    {...solution, board: {...solution.board, id: "44d83467c127dc76", height: solution.board.width - 1}},
                ];
                spyVerifyJwt();
                spyGetUserBySubject();
                spyGetSolutionById(undefined);
                spyGetSolutions(otherSolutions);
                spyGetLevelById({} as Level);
                spyIsSolutionValid(undefined);
                spySaveSolution();
                const saveSolutionSpy = spySaveSolution();
                return post(body)
                    .then(value => {
                        expect(value).toEqual({tag: "Ok"});
                        expect(saveSolutionSpy).toHaveBeenCalled();
                    });
            });
        });
    });
});
