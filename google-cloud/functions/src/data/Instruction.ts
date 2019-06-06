import * as Direction from "./Direction";
import {JsonDecoder} from "ts.data.json";
import * as Int16 from "./Int16";

export function compareFn(a: Instruction, b: Instruction) {
    if (a.tag !== b.tag) {
        return a.tag < b.tag ? -1 : 1;
    }

    let c;
    switch (a.tag) {
        case "ChangeDirection":
            c = b as ChangeDirection;
            return a.direction === c.direction
                ? 0
                : a.direction < c.direction ? -1 : 1;
        case "PushToStack":
            c = b as PushToStack;
            return a.value === c.value
                ? 0
                : a.value < c.value ? -1 : 1;
        case "Branch":
            c = b as Branch;
            return a.trueDirection < c.trueDirection
                ? -1
                : a.trueDirection > c.trueDirection
                    ? 1
                    : a.falseDirection < c.falseDirection
                        ? -1
                        : a.falseDirection > c.falseDirection
                            ? 1
                            : 0;
        case "Exception":
            c = b as Exception;
            return a.exceptionMessage === c.exceptionMessage
                ? 0
                : a.exceptionMessage < c.exceptionMessage ? -1 : 1;
        case "NoOp":
        case "PopFromStack":
        case "JumpForward":
        case "Duplicate":
        case "Swap":
        case "Negate":
        case "Abs":
        case "Not":
        case "Increment":
        case "Decrement":
        case "Add":
        case "Subtract":
        case "Multiply":
        case "Divide":
        case "Equals":
        case "CompareLessThan":
        case "And":
        case "Or":
        case "XOr":
        case "Read":
        case "Print":
        case "Terminate":
        case "SendToBottom":
            return 0;
    }
}

import Decoder = JsonDecoder.Decoder;

export type Instruction
    = NoOp
    | ChangeDirection
    | PushToStack
    | PopFromStack
    | JumpForward
    | Duplicate
    | Swap
    | Negate
    | Abs
    | Not
    | Increment
    | Decrement
    | Add
    | Subtract
    | Multiply
    | Divide
    | Equals
    | CompareLessThan
    | And
    | Or
    | XOr
    | Read
    | Print
    | Branch
    | Terminate
    | SendToBottom
    | Exception;

export interface NoOp {
    readonly tag: "NoOp"
}

export interface ChangeDirection {
    readonly tag: "ChangeDirection",
    readonly direction: Direction.Direction
}

export interface PushToStack {
    readonly tag: "PushToStack",
    readonly value: Int16.Int16
}

export interface PopFromStack {
    readonly tag: "PopFromStack"
}

export interface JumpForward {
    readonly tag: "JumpForward"
}

export interface Duplicate {
    readonly tag: "Duplicate"
}

export interface Swap {
    readonly tag: "Swap"
}

export interface Negate {
    readonly tag: "Negate"
}

export interface Abs {
    readonly tag: "Abs"
}

export interface Not {
    readonly tag: "Not"
}

export interface Increment {
    readonly tag: "Increment"
}

export interface Decrement {
    readonly tag: "Decrement"
}

export interface Add {
    readonly tag: "Add"
}

export interface Subtract {
    readonly tag: "Subtract"
}

export interface Multiply {
    readonly tag: "Multiply"
}

export interface Divide {
    readonly tag: "Divide"
}

export interface Equals {
    readonly tag: "Equals"
}

export interface CompareLessThan {
    readonly tag: "CompareLessThan"
}

export interface And {
    readonly tag: "And"
}

export interface Or {
    readonly tag: "Or"
}

export interface XOr {
    readonly tag: "XOr"
}

export interface Read {
    readonly tag: "Read"
}

export interface Print {
    readonly tag: "Print"
}

export interface Branch {
    readonly tag: "Branch",
    readonly trueDirection: Direction.Direction,
    readonly falseDirection: Direction.Direction
}

export interface Terminate {
    readonly tag: "Terminate"
}

export interface SendToBottom {
    readonly tag: "SendToBottom"
}

export interface Exception {
    readonly tag: "Exception",
    readonly exceptionMessage: string
}

export const decoder: Decoder<Instruction> = JsonDecoder.oneOf<Instruction>(
    [
        JsonDecoder.object({tag: JsonDecoder.isExactly("NoOp")}, "NoOp"),
        JsonDecoder.object({
            tag: JsonDecoder.isExactly("ChangeDirection"),
            direction: Direction.decoder
        }, "ChangeDirection"),
        JsonDecoder.object({
            tag: JsonDecoder.isExactly("PushToStack"),
            value: Int16.decoder
        }, "PushToStack"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("PopFromStack")}, "PopFromStack"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("JumpForward")}, "JumpForward"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Duplicate")}, "Duplicate"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Swap")}, "Swap"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Negate")}, "Negate"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Abs")}, "Abs"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Not")}, "Not"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Increment")}, "Increment"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Decrement")}, "Decrement"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Add")}, "Add"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Subtract")}, "Subtract"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Multiply")}, "Multiply"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Divide")}, "Divide"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Equals")}, "Equals"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("CompareLessThan")}, "CompareLessThan"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("And")}, "And"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Or")}, "Or"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("XOr")}, "XOr"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Read")}, "Read"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Print")}, "Print"),
        JsonDecoder.object({
            tag: JsonDecoder.isExactly("Branch"),
            trueDirection: Direction.decoder,
            falseDirection: Direction.decoder
        }, "Branch"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("Terminate")}, "Terminate"),
        JsonDecoder.object({tag: JsonDecoder.isExactly("SendToBottom")}, "SendToBottom"),
        JsonDecoder.object({
            tag: JsonDecoder.isExactly("Exception"),
            exceptionMessage: JsonDecoder.string
        }, "Exception"),
    ],
    "Instruction"
);
