module Levels exposing (levels)

import Array
import Data.Board as Board
import Data.CampaignId as CampaignId
import Data.Direction exposing (Direction(..))
import Data.Instruction as Instruction exposing (Instruction(..))
import Data.InstructionTool as InstructionTool exposing (InstructionTool(..))
import Data.Int16 as Int16
import Data.Level exposing (Level)


levelTest : Level
levelTest =
    { id = "e182f31307fecaac"
    , index = 0
    , campaignId = CampaignId.standard
    , name = "test"
    , description = [ "For testing purposes" ]
    , io =
        { input =
            List.range 980 1020
                |> List.map Int16.constructor
        , output = []
        }
    , initialBoard =
        Board.empty 3 3
            |> Board.set { x = 2, y = 2 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction (PushToStack Int16.zero)
            , PushValueToStack "0"
            , JustInstruction Add
            , JustInstruction SendToBottom
            , JustInstruction PopFromStack
            , BranchAnyDirection Left Right
            , JustInstruction JumpForward
            , InstructionTool.Exception ""
            ]
    }


levelDoubleTheFun : Level
levelDoubleTheFun =
    { id = "42fe70779bd30656"
    , index = 1
    , campaignId = CampaignId.standard
    , name = "Double the fun"
    , description = [ "> Read a number n from input", "> Output n * 2", "The last input is 0 and should not be printed" ]
    , io =
        { input =
            [ 1, 8, 19, 3, 5, 31, 9, 0 ]
                |> List.map Int16.constructor
        , output =
            [ 2, 16, 38, 6, 10, 62, 18 ]
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 4 4
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Add
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction PopFromStack
            , JustInstruction Terminate
            , BranchAnyDirection Left Right
            ]
    }


level123 : Level
level123 =
    { id = "88c653c6c3a5b5e7"
    , index = 2
    , campaignId = CampaignId.standard
    , name = "One, two, three"
    , description = [ "> Output the numbers 1, 2, and 3" ]
    , io =
        { input = []
        , output =
            [ 1, 2, 3 ]
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 4 4
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Read
            , JustInstruction PopFromStack
            , JustInstruction Print
            , JustInstruction Terminate
            , BranchAnyDirection Left Right
            ]
    }


levelCountDown : Level
levelCountDown =
    { id = "e2f96c5345e5f1f6"
    , index = 3
    , campaignId = CampaignId.standard
    , name = "Count down"
    , description = [ "> Read a number n from input", "> Output all the numbers from n to 0", "The last input is 0 and should not be printed" ]
    , io =
        { input =
            [ 7, 3, 10, 0 ]
                |> List.map Int16.constructor
        , output =
            [ 7, 3, 10 ]
                |> List.map (List.range 0)
                |> List.map List.reverse
                |> List.concat
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 7 7
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Decrement
            , JustInstruction Read
            , JustInstruction PopFromStack
            , JustInstruction Print
            , JustInstruction Terminate
            , BranchAnyDirection Left Right
            ]
    }


levelSomeSums : Level
levelSomeSums =
    { id = "c2003520d988f8d0"
    , index = 4
    , campaignId = CampaignId.standard
    , name = "Some sums"
    , description = [ "> Read two numbers a and b from input", "> Output a + b", "The last input is 0 and should not be printed" ]
    , io =
        { input =
            [ 1, 5, 13, 10, 11, 10, 8, 8, 0 ]
                |> List.map Int16.constructor
        , output =
            [ 6, 23, 21, 16 ]
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 7 7
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction Swap
            , JustInstruction Read
            , JustInstruction PopFromStack
            , JustInstruction Print
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelOneMinusTheOther : Level
levelOneMinusTheOther =
    { id = "1a3c6d6a80769a07"
    , index = 5
    , campaignId = CampaignId.standard
    , name = "One minus the other"
    , description = [ "> Read two numbers a and b from input", "> Output a - b", "The last input is 0 and should not be printed" ]
    , io =
        let
            input =
                [ 18, 4, 9, 17, 13, 13, 12, 1, 17, 3 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> listPairs
                |> List.map (\( a, b ) -> a - b)
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 7 7
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction Swap
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction PopFromStack
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelPowersOfTwo : Level
levelPowersOfTwo =
    { id = "3ee1f15ae601fc94"
    , index = 6
    , campaignId = CampaignId.standard
    , name = "Powers of two"
    , description = [ "> Read a number n from input", "> Output 2^n ", "The last input is 0 and should not be printed" ]
    , io =
        let
            input =
                [ 1, 4, 3, 2, 5, 6 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> List.map ((^) 2)
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 8 8
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction PopFromStack
            , JustInstruction Swap
            , JustInstruction Read
            , JustInstruction Print
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelTriangularNumbers : Level
levelTriangularNumbers =
    { id = "24c7efb5c41f8f8f"
    , index = 7
    , campaignId = CampaignId.standard
    , name = "Triangular numbers"
    , description = [ "> Read a number n from input", "> Output n*(n+1)/2 ", "The last input is 0 and should not be printed" ]
    , io =
        let
            input =
                [ 5, 13, 7, 11, 1, 10, 3 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> List.map (\n -> n * (n + 1) // 2)
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 8 8
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction PopFromStack
            , JustInstruction Swap
            , JustInstruction Read
            , JustInstruction Print
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelSignalAmplifier : Level
levelSignalAmplifier =
    { id = "d3c077ea5033222c"
    , index = 8
    , campaignId = CampaignId.standard
    , name = "Signal amplifier"
    , description = [ "> Read a number x from the input", "> Output x + 10", "The last input is 0 should not be outputed" ]
    , io =
        let
            input =
                [ 24, 145, 49, 175, 166, 94, 38, 90, 165, 211 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> List.map ((+) 10)
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 5 5
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction Swap
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction JumpForward
            , JustInstruction PopFromStack
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelMultiplier : Level
levelMultiplier =
    { id = "bc27b58a0cafb0ba"
    , index = 9
    , campaignId = CampaignId.standard
    , name = "Multiplier"
    , description = [ "> Read two positive numbers x and y from the input", "> Output x * y", "The last input is 0 should not be outputed" ]
    , io =
        let
            input =
                [ 12, 2, 6, 6, 5, 7, 1, 1, 7, 11, 6, 3 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> listPairs
                |> List.map (\( x, y ) -> x * y)
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 7 7
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction Swap
            , JustInstruction SendToBottom
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction JumpForward
            , JustInstruction PopFromStack
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelDivideAndConquer : Level
levelDivideAndConquer =
    { id = "9abf854cff37e96b"
    , index = 10
    , campaignId = CampaignId.standard
    , name = "Divide and conquer"
    , description = [ "> Read two positive numbers x and y from the input", "> Output ⌊x / y⌋", "The last input is 0 should not be outputed" ]
    , io =
        let
            input =
                [ 12, 1, 8, 2, 8, 8, 11, 2, 5, 7, 10, 4 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> listPairs
                |> List.map (\( x, y ) -> x // y)
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 7 7
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction Swap
            , JustInstruction SendToBottom
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction (PushToStack Int16.zero)
            , JustInstruction JumpForward
            , JustInstruction PopFromStack
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelSequenceReverser : Level
levelSequenceReverser =
    { id = "407410b1638112a9"
    , index = 11
    , campaignId = CampaignId.standard
    , name = "Sequence reverser"
    , description = [ "> Read a sequence of numbers from input", "> Output the sequence in reverse", "The last input is 0 is not part of the sequence" ]
    , io =
        let
            input =
                [ -19, -2, 94, -5, 19, 7, 33, -92, 29, -39 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> List.reverse
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 5 5
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction Swap
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction JumpForward
            , JustInstruction PopFromStack
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelSequenceSorter : Level
levelSequenceSorter =
    { id = "b96e6c12476716a3"
    , index = 12
    , campaignId = CampaignId.standard
    , name = "Sequence sorter"
    , description = [ "> Read a sequence from the input", "> Output the sequence sorted from lowest to highest", "The last input is 0 should not be outputed" ]
    , io =
        let
            input =
                [ 1, 4, 3, 7, 11, 15, 4, 14, 4, 10, 8, 7 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> List.sort
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 7 7
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction Swap
            , JustInstruction SendToBottom
            , JustInstruction CompareLessThan
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction JumpForward
            , JustInstruction PopFromStack
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelLessIsMore : Level
levelLessIsMore =
    { id = "1fac7ddba473e99d"
    , index = 13
    , campaignId = CampaignId.standard
    , name = "Less is more"
    , description = [ "> Read two numbers a and b from the input", "> If a < b output a, otherwise output b", "The last input is 0 is not part of the sequence" ]
    , io =
        let
            input =
                [ 6, 15, 11, 3, 9, 7, 15, 15, 3, 7 ]
        in
        { input =
            input
                ++ [ 0 ]
                |> List.map Int16.constructor
        , output =
            input
                |> listPairs
                |> List.map
                    (\( a, b ) ->
                        if a < b then
                            a

                        else
                            b
                    )
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 8 8
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction Duplicate
            , JustInstruction Increment
            , JustInstruction Decrement
            , JustInstruction Swap
            , JustInstruction Read
            , JustInstruction Print
            , JustInstruction JumpForward
            , JustInstruction PopFromStack
            , BranchAnyDirection Left Right
            , JustInstruction Terminate
            ]
    }


levelLabyrinth1 : Level
levelLabyrinth1 =
    { id = "be13bbdd076a586c"
    , index = 14
    , campaignId = CampaignId.standard
    , name = "Labyrinth 1"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 2, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 4 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            ]
    }


levelLabyrinth2 : Level
levelLabyrinth2 =
    { id = "e6d9465e4aacaa0f"
    , index = 15
    , campaignId = CampaignId.standard
    , name = "Labyrinth 2"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 4, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 2 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            ]
    }


levelLabyrinth3 : Level
levelLabyrinth3 =
    { id = "e81d1f82a8a37103"
    , index = 16
    , campaignId = CampaignId.standard
    , name = "Labyrinth 3"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 3, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 2 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction JumpForward
            ]
    }


levelLabyrinth4 : Level
levelLabyrinth4 =
    { id = "e7d5826a6db19981"
    , index = 17
    , campaignId = CampaignId.standard
    , name = "Labyrinth 4"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 1, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 3 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Right
            , JustInstruction JumpForward
            ]
    }


levelLabyrinth5 : Level
levelLabyrinth5 =
    { id = "519983570eefe19c"
    , index = 18
    , campaignId = CampaignId.standard
    , name = "Labyrinth 5"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 4, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 2 } (PushToStack Int16.one)
            |> Board.set { x = 3, y = 4 } (Branch Right Up)
            |> Board.set { x = 4, y = 4 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Down
            ]
    }


levelLabyrinth6 : Level
levelLabyrinth6 =
    { id = "81101cdad21a4ed2"
    , index = 19
    , campaignId = CampaignId.standard
    , name = "Labyrinth 6"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 0, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 1 } (PushToStack Int16.one)
            |> Board.set { x = 2, y = 3 } (Branch Right Up)
            |> Board.set { x = 3, y = 3 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Down
            , JustInstruction JumpForward
            ]
    }


levelLabyrinth7 : Level
levelLabyrinth7 =
    { id = "36ae04449442c355"
    , index = 20
    , campaignId = CampaignId.standard
    , name = "Labyrinth 7"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 3, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 1 } Increment
            |> Board.set { x = 2, y = 3 } (Branch Right Left)
            |> Board.set { x = 3, y = 3 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Down
            , BranchAnyDirection Up Up
            , JustInstruction JumpForward
            ]
    }


levelLabyrinth8 : Level
levelLabyrinth8 =
    { id = "42cdf083b26bb8ab"
    , index = 21
    , campaignId = CampaignId.standard
    , name = "Labyrinth 8"
    , description = [ "> Output 1, 2, 3, 4", "> Terminate the program" ]
    , io =
        { input = []
        , output =
            [ 1, 2, 3, 4 ]
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 2, y = 1 } Increment
            |> Board.set { x = 3, y = 1 } Print
            |> Board.set { x = 2, y = 2 } Print
            |> Board.set { x = 3, y = 2 } Increment
            |> Board.set { x = 4, y = 0 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Down
            ]
    }


levelLabyrinth9 : Level
levelLabyrinth9 =
    { id = "5ed6d025ab5937e4"
    , index = 22
    , campaignId = CampaignId.standard
    , name = "Labyrinth 9"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 2, y = 1 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 0 } JumpForward
            |> Board.set { x = 0, y = 1 } JumpForward
            |> Board.set { x = 1, y = 2 } JumpForward
            |> Board.set { x = 3, y = 2 } JumpForward
            |> Board.set { x = 4, y = 3 } JumpForward
            |> Board.set { x = 1, y = 4 } JumpForward
            |> Board.set { x = 2, y = 4 } JumpForward
            |> Board.set { x = 3, y = 4 } JumpForward
            |> Board.set { x = 2, y = 2 } Terminate
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Down
            ]
    }


levelLabyrinth10 : Level
levelLabyrinth10 =
    { id = "b4c862e5dcfb82c1"
    , index = 23
    , campaignId = CampaignId.standard
    , name = "Labyrinth 10"
    , description = [ "> Output 1", "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output =
            [ 1 ]
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 0, y = 2 } JumpForward
            |> Board.set { x = 0, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 4 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 1, y = 0 } JumpForward
            |> Board.set { x = 1, y = 2 } (Branch Left Up)
            |> Board.set { x = 2, y = 1 } JumpForward
            |> Board.set { x = 2, y = 2 } Terminate
            |> Board.set { x = 2, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 2 } (Branch Right Up)
            |> Board.set { x = 3, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 3, y = 4 } JumpForward
            |> Board.set { x = 4, y = 1 } JumpForward
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Down
            , JustInstruction Increment
            , JustInstruction Print
            ]
    }


levelLabyrinth11 : Level
levelLabyrinth11 =
    { id = "f8ba39bc9d01ef03"
    , index = 24
    , campaignId = CampaignId.standard
    , name = "Labyrinth 11"
    , description = [ "> Output 1", "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output =
            [ 1 ]
                |> List.map Int16.constructor
        }
    , initialBoard =
        Board.empty 5 5
            |> Board.set { x = 2, y = 0 } JumpForward
            |> Board.set { x = 3, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 4, y = 0 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 1 } JumpForward
            |> Board.set { x = 2, y = 1 } (Branch Up Right)
            |> Board.set { x = 1, y = 2 } JumpForward
            |> Board.set { x = 2, y = 2 } Terminate
            |> Board.set { x = 3, y = 2 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 0, y = 3 } (Instruction.Exception "Don't hit the exceptions")
            |> Board.set { x = 2, y = 3 } (Branch Down Right)
            |> Board.set { x = 4, y = 3 } JumpForward
            |> Board.set { x = 1, y = 4 } JumpForward
            |> Board.set { x = 2, y = 4 } Increment
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Down
            , JustInstruction Print
            ]
    }


levelLabyrinthLab : Level
levelLabyrinthLab =
    { id = "572b4066ff5a9bd9"
    , index = 25
    , campaignId = CampaignId.standard
    , name = "Labyrinth lab"
    , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
    , io =
        { input = []
        , output = []
        }
    , initialBoard =
        Board.empty 5 5
    , instructionTools =
        Array.fromList
            [ JustInstruction NoOp
            , ChangeAnyDirection Down
            , JustInstruction (Instruction.Exception "")
            , JustInstruction Terminate
            , BranchAnyDirection Up Left
            , PushValueToStack "1"
            , JustInstruction JumpForward
            , JustInstruction Print
            , JustInstruction Increment
            , JustInstruction Decrement
            ]
    }


levels : List Level
levels =
    let
        lvls =
            [ level123
            , levelDoubleTheFun
            , levelCountDown
            , levelSomeSums
            , levelSignalAmplifier
            , levelOneMinusTheOther
            , levelPowersOfTwo
            , levelTriangularNumbers
            , levelMultiplier
            , levelDivideAndConquer
            , levelSequenceReverser
            , levelSequenceSorter
            , levelLessIsMore
            , levelLabyrinth1
            , levelLabyrinth2
            , levelLabyrinth3
            , levelLabyrinth4
            , levelLabyrinth5
            , levelLabyrinth6
            , levelLabyrinth7
            , levelLabyrinth8
            , levelLabyrinth9
            , levelLabyrinth10
            , levelLabyrinth11
            ]

        -- a =
        --     lvls |> list JsonUtils.encodeLevel |> JsonUtils.toString |> Debug.log "levels:"
    in
    lvls


listPairs : List a -> List ( a, a )
listPairs list =
    case list of
        a :: b :: tail ->
            ( a, b ) :: listPairs tail

        _ ->
            []
