import {Request} from "express";
import {expectArraySameContent, randomId, range} from "../utils";
import {Draft} from "../../../main/ts/data/Draft";
import * as DraftDto from "../../../main/ts/data/dto/DraftDto";
import {BadRequest, EndpointResult, Found, invalidAccessToken} from "../../../main/ts/data/EndpointResult";
import * as Result from "../../../main/ts/data/Result";
import {endpoint} from "../../../main/ts/endpoint/draft";
import drafts from "../../resources/drafts/index";
import * as spies from "../spies";

jest.mock("../../../main/ts/service/firestore");

const defaultDraft = DraftDto.decodeOrThrow(drafts.b3e9a55d719d8200);

beforeEach(() => {
    spies.verifyJwt();
    spies.getUserBySubject();
    spies.getDrafts();
    spies.getDraftById();
});

describe("get", () => {
    async function get(params: { draftId?: string, levelId?: string } = {}): Promise<EndpointResult<Draft | Draft[]>> {
        return endpoint({method: "GET", query: params} as Request);
    }

    describe("authorization", () => {
        test("should return forbidden if verify jwt fails", () => {
            const messages = ["some invalid access token message"];
            spies.verifyJwt(Result.failure(invalidAccessToken(messages)));
            return get()
                .then(value => {
                    expect(value).toEqual({
                        tag: "InvalidAccessToken", messages,
                    });
                });
        });

        test("should request scope read:drafts", () => {
            const verifyJwt = spies.verifyJwt();
            return get()
                .then(() => {
                    expect(verifyJwt.mock.calls[0][1]).toContain("read:drafts");
                });
        });
    });

    describe("bad request", () => {
        test("should return bad request if draftId is not a string", () => {
            return get({draftId: {} as string})
                .then(value => {
                    expect(value.tag).toEqual("BadRequest");
                    expect((value as BadRequest).messages[0]).toMatch(/\bdraftId\b/);
                });
        });

        test("should return bad request if levelId is not a string", () => {
            return get({levelId: {} as string})
                .then(value => {
                    expect(value.tag).toEqual("BadRequest");
                    expect((value as BadRequest).messages[0]).toMatch(/\blevelId\b/);
                });
        });
    });

    describe("get by draft id", () => {
        test("should return not found if draft doesn't exist", () => {
            const draftId = "a91073e9b54813dd";
            const getDraftById = spies.getDraftById(undefined);
            return get({draftId})
                .then(value => {
                    expect(value.tag).toEqual("NotFound");
                    expect(getDraftById).toHaveBeenCalledWith(draftId);
                });
        });

        test("should return forbidden if another user owns the draft", () => {
            const draft = {...defaultDraft, authorId: `not-${spies.defaultTestUserId}`};
            spies.getDraftById(draft);
            return get({draftId: draft.id})
                .then(value => {
                    expect(value.tag).toEqual("Forbidden");
                });
        });

        test("should return draft if it exists and you own it", () => {
            const draft = defaultDraft;
            spies.getDraftById(draft);
            return get({draftId: draft.id})
                .then(value => {
                    expect(value.tag).toEqual("Found");
                    expect((value as Found<DraftDto.DraftDto>).body).toEqual(DraftDto.encode(draft));
                });
        });
    });

    describe("get by level id", () => {
        test("should return all your drafts that have the specified level id", () => {
            const levelId = "5e61b4d3689b28d3";
            const repoDrafts = range(10).map(() => ({...defaultDraft, id: randomId(), levelId}));
            const getDrafts = spies.getDrafts(repoDrafts);
            return get({levelId})
                .then(value => {
                    expect(value.tag).toEqual("Found");
                    expectArraySameContent((value as Found<DraftDto.DraftDto[]>).body, repoDrafts.map(DraftDto.encode));
                    expect(getDrafts).toHaveBeenCalledWith({levelId, authorId: spies.defaultTestUserId});
                });
        });

        test("should return all your drafts if level id not specified", () => {
            const repoDrafts = range(10).map(() => ({...defaultDraft, id: randomId(), levelId: randomId()}));
            const getDrafts = spies.getDrafts(repoDrafts);
            return get()
                .then(value => {
                    expect(value.tag).toEqual("Found");
                    expectArraySameContent((value as Found<DraftDto.DraftDto[]>).body, repoDrafts.map(DraftDto.encode));
                    expect(getDrafts).toHaveBeenCalledWith({authorId: spies.defaultTestUserId});
                });
        });
    });
});
