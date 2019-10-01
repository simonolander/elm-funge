import {Request} from "express";
import {Blueprint} from "../../../main/ts/data/Blueprint";
import {BadRequest, EndpointResult, Forbidden, invalidAccessToken} from "../../../main/ts/data/EndpointResult";
import * as Result from "../../../main/ts/data/Result";
import {endpoint} from "../../../main/ts/endpoint/blueprints";
import * as spies from "../spies";
import {defaultTestUserId, notTestUserId} from "../spies";
import {randomId} from "../utils";

jest.mock("../../../main/ts/service/firestore");

const defaultBlueprint: Blueprint = {
    id: randomId(),
    name: "75ahg6a6bpe2m5im",
    description: ["bmz3lb2it4uy1uk2", "hi3o3yeg3ext3jz0"],
    suites: [{input: [], output: []}],
    initialBoard: {width: 4, height: 3, instructions: []},
    instructionTools: [],
    authorId: defaultTestUserId,
    createdTime: 1569670000,
    modifiedTime: 1569680000,
};

beforeEach(() => {
    spies.verifyJwt();
    spies.getUserBySubject();
    spies.getBlueprintById();
});

describe("delete", () => {
    async function del(params: { blueprintId?: string } = {}): Promise<EndpointResult<void>> {
        return endpoint({method: "DELETE", query: params} as Request);
    }

    describe("authorization", () => {
        test("should return forbidden if verify jwt fails", () => {
            const messages = ["some invalid access token message"];
            spies.verifyJwt(Result.failure(invalidAccessToken(messages)));
            return del()
                .then(value => {
                    expect(value).toEqual({
                        tag: "InvalidAccessToken", messages,
                    });
                });
        });

        test("should request scope edit:blueprints", () => {
            const verifyJwt = spies.verifyJwt();
            return del()
                .then(() => {
                    expect(verifyJwt.mock.calls[0][1]).toContain("edit:blueprints");
                });
        });
    });

    describe("bad request", () => {
        test("should return bad request if blueprintId is not a string", () => {
            return del({blueprintId: {} as string})
                .then(value => {
                    expect(value.tag).toEqual("BadRequest");
                    expect((value as BadRequest).messages[0]).toMatch(/\bblueprintId\b/);
                });
        });
    });

    describe("forbidden", () => {
        test("should return forbidden if not your blueprint", () => {
            const blueprintId = defaultBlueprint.id;
            spies.getBlueprintById({ ...defaultBlueprint, authorId: notTestUserId});
            return del({blueprintId}).then(value => {
                expect(value.tag).toEqual("Forbidden");
                expect((value as Forbidden).messages[0]).toContain(blueprintId);
                expect((value as Forbidden).messages[0]).toContain("delete");
            });
        });
    });

    describe("happy case", () => {
        test("should return ok if deleting your blueprint", () => {
            const blueprintId = defaultBlueprint.id;
            spies.getBlueprintById(defaultBlueprint);
            const deleteBlueprint = spies.deleteBlueprint();
            return del({blueprintId}).then(value => {
                expect(value.tag).toEqual("Ok");
                expect(deleteBlueprint).toHaveBeenCalledWith(blueprintId);
            });
        });

        test("should return ok if blueprint doesn't exist", () => {
            const blueprintId = defaultBlueprint.id;
            spies.getBlueprintById(undefined);
            const deleteBlueprint = spies.deleteBlueprint();
            return del({blueprintId}).then(value => {
                expect(value.tag).toEqual("Ok");
                expect(deleteBlueprint).not.toHaveBeenCalled();
            });
        });
    });
});
