import {JsonDecoder} from "ts.data.json";
import * as Instruction from "./Instruction";

export type InstructionTool
    = JustInstruction
    | ChangeAnyDirection
    | BranchAnyDirection
    | PushValueToStack
    | Exception;

export interface JustInstruction {
    readonly tag: "JustInstruction",
    readonly instruction: Instruction.Instruction
}

export interface ChangeAnyDirection {
    readonly tag: "ChangeAnyDirection"
}

export interface BranchAnyDirection {
    readonly tag: "BranchAnyDirection"
}

export interface PushValueToStack {
    readonly tag: "PushValueToStack"
}

export interface Exception {
    readonly tag: "Exception",
}

export const decoder: JsonDecoder.Decoder<InstructionTool> = JsonDecoder.oneOf<InstructionTool>(
    [
        JsonDecoder.object({tag: JsonDecoder.isExactly("ChangeAnyDirection")}, "ChangeAnyDirection"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("BranchAnyDirection")}, "BranchAnyDirection"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("PushValueToStack")}, "PushValueToStack"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Exception")}, "Exception"),
        JsonDecoder.object({
            tag: JsonDecoder.isExactly("JustInstruction"),
            instruction: Instruction.decoder
        }, "JustInstruction")
    ],
    "InstructionTool"
);
