import {JsonDecoder} from "ts.data.json";
import * as Board from "./Board";
import * as InstructionTool from "./InstructionTool";
import * as IO from "./IO";
import * as Integer from "./Integer"

export interface PostLevelRequest {
    readonly id: string,
    readonly index: number,
    readonly campaignId: string,
    readonly name: string,
    readonly description: Array<string>,
    readonly io: IO.IO,
    readonly initialBoard: Board.Board,
    readonly instructionTools: Array<InstructionTool.InstructionTool>,
    readonly version: number
}

export const decoder: JsonDecoder.Decoder<PostLevelRequest> = JsonDecoder.object({
    id: JsonDecoder.string,
    index: Integer.nonNegativeDecoder,
    campaignId: JsonDecoder.string,
    name: JsonDecoder.string,
    description: JsonDecoder.array(JsonDecoder.string, "description"),
    io: IO.decoder,
    initialBoard: Board.decoder,
    instructionTools: JsonDecoder.array(InstructionTool.decoder, "instructionTools"),
    version: Integer.nonNegativeDecoder
}, "PostLevelRequest");
