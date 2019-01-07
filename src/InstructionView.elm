module InstructionView exposing (description, view)

import Element exposing (..)
import Element.Font as Font
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
            "Peek the stack. If the value is not zero, go left, otherwise go left"

        Branch Left Up ->
            "Peek the stack. If the value is not zero, go left, otherwise go up"

        Branch Left Right ->
            "Peek the stack. If the value is not zero, go left, otherwise go right"

        Branch Left Down ->
            "Peek the stack. If the value is not zero, go left, otherwise go down"

        Branch Up Left ->
            "Peek the stack. If the value is not zero, go up, otherwise go left"

        Branch Up Up ->
            "Peek the stack. If the value is not zero, go up, otherwise go up"

        Branch Up Right ->
            "Peek the stack. If the value is not zero, go up, otherwise go right"

        Branch Up Down ->
            "Peek the stack. If the value is not zero, go up, otherwise go down"

        Branch Right Left ->
            "Peek the stack. If the value is not zero, go right, otherwise go left"

        Branch Right Up ->
            "Peek the stack. If the value is not zero, go right, otherwise go up"

        Branch Right Right ->
            "Peek the stack. If the value is not zero, go right, otherwise go right"

        Branch Right Down ->
            "Peek the stack. If the value is not zero, go right, otherwise go down"

        Branch Down Left ->
            "Peek the stack. If the value is not zero, go down, otherwise go left"

        Branch Down Up ->
            "Peek the stack. If the value is not zero, go down, otherwise go up"

        Branch Down Right ->
            "Peek the stack. If the value is not zero, go down, otherwise go right"

        Branch Down Down ->
            "Peek the stack. If the value is not zero, go down, otherwise go down"

        Add ->
            "Pop the top two values from the stack, add them, and push the result to the stack"

        Subtract ->
            "Pop the top value a and the second value b from the stack, and push b - a to the stack"

        Read ->
            "Pop the top value from the input and push it to the stack"

        Print ->
            "Peek the top value from the stack and push it to the output"

        Duplicate ->
            "Duplicate the top value in the stack"

        Increment ->
            "Pop the top value a from the stack and push a + 1 to the stack"

        Decrement ->
            "Pop the top value a from the stack and push a - 1 to the stack"

        Swap ->
            "Swap the top two values in the stack"

        PopFromStack ->
            "Discard the top value from the stack"

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

        PushToStack value ->
            "Push " ++ String.fromInt value ++ " to the stack"

        Negate ->
            "TODO: Negate the top value of the stack"

        Abs ->
            "TODO: Replace the top value of the stack with it's absolute value"

        Not ->
            "TODO: If the top value of the stack is 0, replace it with 1, otherwise replace it with 0"

        Multiply ->
            "TODO: Peek"

        Divide ->
            "TODO: Divide"

        Equals ->
            "TODO: Equals"

        And ->
            "TODO: And"

        Or ->
            "TODO: Or"

        XOr ->
            "TODO: XOr"


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

        PushToStack value ->
            String.fromInt value
                |> text
                |> el ([ Font.size 26, centerY ] ++ attributes)

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
            "TODO"
                |> text
                |> el ([ Font.size 26, centerY ] ++ attributes)
