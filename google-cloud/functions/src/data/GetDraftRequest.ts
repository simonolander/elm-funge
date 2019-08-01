import {JsonDecoder} from "ts.data.json";

export interface GetDraftRequest {
    draftId?: string;
    levelId?: string;
}

export const decoder: JsonDecoder.Decoder<GetDraftRequest> = JsonDecoder.object({
    draftId: JsonDecoder.oneOf([
        JsonDecoder.string,
        JsonDecoder.isUndefined(undefined),
    ], "draftId | undefined"),
    levelId: JsonDecoder.oneOf([
        JsonDecoder.string,
        JsonDecoder.isUndefined(undefined),
    ], "levelId | undefined"),
}, "GetDraftRequest");
