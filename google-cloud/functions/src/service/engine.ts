import * as Board from "../data/Board";
import {Direction} from "../data/Direction";
import * as Instruction from "../data/Instruction";
import * as InstructionTool from "../data/InstructionTool";
import * as Int16 from "../data/Int16";
import {Level} from "../data/Level";
import {Score} from "../data/Score";

const MAX_STEPS = 10000000;

export function isSolutionValid(level: Level, board: Board.Board, score: Score): string | undefined {
    if (level.initialBoard.width !== board.width) {
        return `Invalid board width, excepted ${level.initialBoard.width} but was ${board.width}`;
    }

    if (level.initialBoard.height !== board.height) {
        return `Invalid board height, excepted ${level.initialBoard.height} but was ${board.height}`;
    }

    if (score.numberOfInstructions < 0 || !isFinite(score.numberOfInstructions)) {
        return `Invalid score, cannot have ${score.numberOfInstructions} instructions`;
    }

    if (score.numberOfSteps < 1 || !isFinite(score.numberOfSteps)) {
        return `Invalid score, cannot have ${score.numberOfSteps} numberOfSteps`;
    }

    if (score.numberOfSteps > MAX_STEPS) {
        return `Number of steps too large, cannot be higher than ${MAX_STEPS} but was ${score.numberOfSteps}`;
    }

    const matrix = Board.toMatrix(board);

    for (const {position, instruction} of level.initialBoard.instructions) {
        if (instruction.tag === "NoOp") {
            continue;
        }
        if (Instruction.compareFn(instruction, matrix[position.x][position.y]) !== 0) {
            return `Invalid board, cannot overwrite fixed instruction at position (${position.x}, ${position.y})`;
        }
    }

    if (!board.instructions.some(({instruction}) => instruction.tag === "Terminate")) {
        return "Invalid board, must contain at least one terminate instruction";
    }

    if (level.io.output.length !== 0 && !board.instructions.some(({instruction}) => instruction.tag === "Print")) {
        return "Invalid board, level contains expected output but board has no print instruction";
    }

    const levelMatrix = Board.toMatrix(level.initialBoard);
    for (const {position, instruction} of board.instructions) {
        if (instruction.tag === "NoOp") {
            continue;
        }

        if (Instruction.compareFn(instruction, levelMatrix[position.x][position.y]) === 0) {
            continue;
        }

        if (!level.instructionTools.some(tool => InstructionTool.canMakeInstruction(tool, instruction))) {
            return `Invalid instruction, no instruction tool in the level can make the instruction ${Instruction.toString(instruction)}`;
        }
    }

    const actualNumberOfInstructions = board.instructions
        .filter(({position, instruction}) => Instruction.compareFn(instruction, levelMatrix[position.x][position.y]) !== 0)
        .length;
    if (actualNumberOfInstructions !== score.numberOfInstructions) {
        return `Invalid score, expected number of instructions to be ${score.numberOfInstructions} but was ${actualNumberOfInstructions}`;
    }

    const currentBoard = Board.toMatrix(board);
    const currentInput = [...level.io.input];
    const currentOutput: Int16.Int16[] = [];
    const currentStack: Int16.Int16[] = [];
    let x = 0;
    let y = 0;
    let direction: Direction = "Right";
    let terminated = false;
    let step: number;

    function pop(): Int16.Int16 {
        const value = currentStack.pop();
        return typeof value === "undefined"
            ? 0
            : value;
    }

    function peek(i = 0): Int16.Int16 {
        const value = currentStack[currentStack.length - 1 - i];
        return typeof value === "undefined"
            ? 0
            : value;
    }

    function push(...values: number[]) {
        for (const value of values) {
            currentStack.push(Int16.fromNumber(value));
        }
    }

    for (step = 0; step < score.numberOfSteps; ++step) {
        const instruction = currentBoard[x][y];
        switch (instruction.tag) {
            case "NoOp":
                break;
            case "ChangeDirection":
                direction = instruction.direction;
                break;
            case "PushToStack":
                push(instruction.value);
                break;
            case "PopFromStack":
                pop();
                break;
            case "JumpForward":
                switch (direction) {
                    case "Right":
                        x = (x + 1) % board.width;
                        break;
                    case "Left":
                        x = (x + board.width - 1) % board.width;
                        break;
                    case "Up":
                        y = (y + 1) % board.height;
                        break;
                    case "Down":
                        y = (y + board.height - 1) % board.height;
                        break;
                }
                break;
            case "Duplicate":
                push(peek());
                break;
            case "Swap":
                push(pop(), pop());
                break;
            case "Negate":
                push(pop() * -1);
                break;
            case "Abs":
                push(Math.abs(pop()));
                break;
            case "Not":
                const value = pop();
                push(value === 0 ? 1 : 0);
                break;
            case "Increment":
                push(pop() + 1);
                break;
            case "Decrement":
                push(pop() - 1);
                break;
            case "Add":
                push(pop() + pop());
                break;
            case "Subtract":
                const sub1 = pop();
                const sub2 = pop();
                push(sub2 - sub1);
                break;
            case "Multiply":
                push(pop() * pop());
                break;
            case "Divide":
                const div1 = pop();
                const div2 = pop();
                push(Math.trunc(div2 / div1));
                break;
            case "Equals":
                push(pop() === pop() ? 1 : 0);
                break;
            case "CompareLessThan":
                push(peek(0) < peek(1) ? 1 : 0);
                break;
            case "And":
                push(pop() !== 0 && pop() !== 0 ? 1 : 0);
                break;
            case "Or":
                push(pop() !== 0 || pop() !== 0 ? 1 : 0);
                break;
            case "XOr":
                push((pop() !== 0) !== (pop() !== 0) ? 1 : 0);
                break;
            case "Read":
                const input = currentInput.pop();
                push(typeof input === "undefined" ? 0 : 1);
                break;
            case "Print":
                currentOutput.push(peek());
                if (currentOutput[currentOutput.length - 1] !== level.io.output[currentOutput.length - 1]) {
                    return `Invalid output on line ${currentOutput.length - 1}, expected ${level.io.output[currentOutput.length - 1]} but was ${currentOutput[currentOutput.length - 1]}`;
                }
                break;
            case "Branch":
                direction = peek() === 0 ? instruction.falseDirection : instruction.trueDirection;
                break;
            case "Terminate":
                terminated = true;
                break;
            case "SendToBottom":
                currentStack.unshift(pop());
                break;
            case "Exception":
                return `Exception encountered when running solution: "${instruction.exceptionMessage}"`;
        }

        if (terminated) {
            break;
        }

        switch (direction) {
            case "Right":
                x = (x + 1) % board.width;
                break;
            case "Left":
                x = (x + board.width - 1) % board.width;
                break;
            case "Up":
                y = (y + 1) % board.height;
                break;
            case "Down":
                y = (y + board.height - 1) % board.height;
                break;
        }
    }

    const numberOfSteps = step + 1;

    if (!terminated) {
        return `Solution did not terminate after ${score.numberOfSteps} steps`;
    }

    if (currentOutput.length !== level.io.output.length) {
        return `Invalid output, expected ${level.io.output.length} lines but was ${currentOutput.length}`;
    }

    for (let line = 0; line < currentOutput.length; ++line) {
        if (currentOutput[line] !== level.io.output[line]) {
            return `Invalid output on line ${line}, expected ${level.io.output[line]} but was ${currentOutput[line]}`;
        }
    }

    if (numberOfSteps !== score.numberOfSteps) {
        return `Invalid score, expected number of steps to be ${numberOfSteps} but was ${score.numberOfSteps}`;
    }

    return undefined;
}
