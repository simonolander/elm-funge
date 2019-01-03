module InstructionView exposing (description, view)

import Element exposing (..)
import Model exposing (..)


description : Instruction -> String
description instruction =
    case instruction of
        NoOp ->
            "Do nothing"

        ChangeDirection Left ->
            "Change the direction of the instruction pointer to left"

        ChangeDirection Up ->
            "Change the direction of the instruction pointer to up"

        ChangeDirection Right ->
            "Change the direction of the instruction pointer to right"

        ChangeDirection Down ->
            "Change the direction of the instruction pointer to down"

        Branch Left Left ->
            "Pop the stack. If the value is not zero, go left, otherwise go left"

        Branch Left Up ->
            "Pop the stack. If the value is not zero, go left, otherwise go up"

        Branch Left Right ->
            "Pop the stack. If the value is not zero, go left, otherwise go right"

        Branch Left Down ->
            "Pop the stack. If the value is not zero, go left, otherwise go down"

        Branch Up Left ->
            "Pop the stack. If the value is not zero, go up, otherwise go left"

        Branch Up Up ->
            "Pop the stack. If the value is not zero, go up, otherwise go up"

        Branch Up Right ->
            "Pop the stack. If the value is not zero, go up, otherwise go right"

        Branch Up Down ->
            "Pop the stack. If the value is not zero, go up, otherwise go down"

        Branch Right Left ->
            "Pop the stack. If the value is not zero, go right, otherwise go left"

        Branch Right Up ->
            "Pop the stack. If the value is not zero, go right, otherwise go up"

        Branch Right Right ->
            "Pop the stack. If the value is not zero, go right, otherwise go right"

        Branch Right Down ->
            "Pop the stack. If the value is not zero, go right, otherwise go down"

        Branch Down Left ->
            "Pop the stack. If the value is not zero, go down, otherwise go left"

        Branch Down Up ->
            "Pop the stack. If the value is not zero, go down, otherwise go up"

        Branch Down Right ->
            "Pop the stack. If the value is not zero, go down, otherwise go right"

        Branch Down Down ->
            "Pop the stack. If the value is not zero, go down, otherwise go down"

        Add ->
            "Pop the top two values from the stack, add them, and push the result to the stack"

        Subtract ->
            "Pop the top value a and the second value b from the stack, and push b - a to the stack"

        Read ->
            "Pop the top value from the input and push it to the stack"

        Print ->
            "Pop the top value from the stack and push it to the output"

        Duplicate ->
            "Pop the top value from the stack and push two copies of the value to the stack"

        Increment ->
            "Pop the top value a from the stack and push a + 1 to the stack"

        Decrement ->
            "Pop the top value a from the stack and push a - 1 to the stack"

        Swap ->
            "Pop the top two value a and b from the stack, push a to the stack, then push b to the stack"

        PopFromStack ->
            "Pop the top value from the stack and discard it"

        Jump Forward ->
            "Move the instruction pointer two steps in the current direction"

        Terminate ->
            "End the program"

        SendToBottom ->
            "Move the top value of the stack to the bottom of the stack"

        CompareLessThan ->
            "Peek at the top two values a and b in the stack, if a < b push 1 to the stack, otherwize push 0 to the stack"

        Exception message ->
            message

        _ ->
            Debug.toString instruction


view : List (Attribute msg) -> Instruction -> Element msg
view attributes instruction =
    case instruction of
        NoOp ->
            el attributes none

        ChangeDirection Left ->
            image attributes
                { src = "assets/instruction-images/change-direction-left.svg"
                , description = description instruction
                }

        ChangeDirection Up ->
            image attributes
                { src = "assets/instruction-images/change-direction-up.svg"
                , description = description instruction
                }

        ChangeDirection Right ->
            image attributes
                { src = "assets/instruction-images/change-direction-right.svg"
                , description = description instruction
                }

        ChangeDirection Down ->
            image attributes
                { src = "assets/instruction-images/change-direction-down.svg"
                , description = description instruction
                }

        Branch Left Left ->
            image attributes
                { src = "assets/instruction-images/branch-left-left.svg"
                , description = description instruction
                }

        Branch Left Up ->
            image attributes
                { src = "assets/instruction-images/branch-left-up.svg"
                , description = description instruction
                }

        Branch Left Right ->
            image attributes
                { src = "assets/instruction-images/branch-left-right.svg"
                , description = description instruction
                }

        Branch Left Down ->
            image attributes
                { src = "assets/instruction-images/branch-left-down.svg"
                , description = description instruction
                }

        Branch Up Left ->
            image attributes
                { src = "assets/instruction-images/branch-up-left.svg"
                , description = description instruction
                }

        Branch Up Up ->
            image attributes
                { src = "assets/instruction-images/branch-up-up.svg"
                , description = description instruction
                }

        Branch Up Right ->
            image attributes
                { src = "assets/instruction-images/branch-up-right.svg"
                , description = description instruction
                }

        Branch Up Down ->
            image attributes
                { src = "assets/instruction-images/branch-up-down.svg"
                , description = description instruction
                }

        Branch Right Left ->
            image attributes
                { src = "assets/instruction-images/branch-right-left.svg"
                , description = description instruction
                }

        Branch Right Up ->
            image attributes
                { src = "assets/instruction-images/branch-right-up.svg"
                , description = description instruction
                }

        Branch Right Right ->
            image attributes
                { src = "assets/instruction-images/branch-right-right.svg"
                , description = description instruction
                }

        Branch Right Down ->
            image attributes
                { src = "assets/instruction-images/branch-right-down.svg"
                , description = description instruction
                }

        Branch Down Left ->
            image attributes
                { src = "assets/instruction-images/branch-down-left.svg"
                , description = description instruction
                }

        Branch Down Up ->
            image attributes
                { src = "assets/instruction-images/branch-down-up.svg"
                , description = description instruction
                }

        Branch Down Right ->
            image attributes
                { src = "assets/instruction-images/branch-down-right.svg"
                , description = description instruction
                }

        Branch Down Down ->
            image attributes
                { src = "assets/instruction-images/branch-down-down.svg"
                , description = description instruction
                }

        Add ->
            image attributes
                { src = "assets/instruction-images/add.svg"
                , description = description instruction
                }

        Subtract ->
            image attributes
                { src = "assets/instruction-images/subtract.svg"
                , description = description instruction
                }

        Read ->
            image attributes
                { src = "assets/instruction-images/read.svg"
                , description = description instruction
                }

        Print ->
            image attributes
                { src = "assets/instruction-images/print.svg"
                , description = description instruction
                }

        Duplicate ->
            image attributes
                { src = "assets/instruction-images/duplicate.svg"
                , description = description instruction
                }

        Increment ->
            image attributes
                { src = "assets/instruction-images/increment.svg"
                , description = description instruction
                }

        Decrement ->
            image attributes
                { src = "assets/instruction-images/decrement.svg"
                , description = description instruction
                }

        Swap ->
            image attributes
                { src = "assets/instruction-images/swap.svg"
                , description = description instruction
                }

        PopFromStack ->
            image attributes
                { src = "assets/instruction-images/pop-from-stack.svg"
                , description = description instruction
                }

        Jump Forward ->
            image attributes
                { src = "assets/instruction-images/jump-one-forward.svg"
                , description = description instruction
                }

        Terminate ->
            image attributes
                { src = "assets/instruction-images/terminate.svg"
                , description = description instruction
                }

        Exception _ ->
            image attributes
                { src = "assets/instruction-images/exception.svg"
                , description = description instruction
                }

        SendToBottom ->
            image attributes
                { src = "assets/instruction-images/send-to-bottom.svg"
                , description = description instruction
                }

        CompareLessThan ->
            image attributes
                { src = "assets/instruction-images/compare-less-than.svg"
                , description = description instruction
                }

        _ ->
            el attributes (text (Debug.toString instruction))
