module Main exposing (main)

import BoardUtils
import Browser
import Browser.Events
import History
import Model exposing (..)
import Time
import Update
import View


init : WindowSize -> ( Model, Cmd Msg )
init windowSize =
    let
        levels : List Level
        levels =
            [ { id = "e182f31307fecaac"
              , name = "test"
              , description = [ "For testing purposes" ]
              , io =
                    { input = List.range 980 1020
                    , output = []
                    }
              , initialBoard =
                    BoardUtils.empty 3 3
                        |> BoardUtils.set { x = 2, y = 2 } Terminate
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Read
                    , JustInstruction Print
                    , JustInstruction Add
                    , JustInstruction SendToBottom
                    , BranchAnyDirection Left Right
                    , JustInstruction (Jump Forward)
                    , JustInstruction (Exception "Some exception")
                    ]
              }
            , { id = "42fe70779bd30656"
              , name = "Double the fun"
              , description = [ "> Read a number n from input", "> Output n * 2", "The last input is 0 and should not be printed" ]
              , io =
                    { input = [ 1, 8, 19, 3, 5, 31, 9, 0 ]
                    , output = [ 2, 16, 38, 6, 10, 62, 18 ]
                    }
              , initialBoard =
                    BoardUtils.empty 4 4
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Add
                    , JustInstruction Read
                    , JustInstruction Print
                    , JustInstruction Terminate
                    , BranchAnyDirection Left Right
                    ]
              }
            , { id = "88c653c6c3a5b5e7"
              , name = "One, two, three"
              , description = [ "> Output the numbers 1, 2, and 3" ]
              , io =
                    { input = []
                    , output = [ 1, 2, 3 ]
                    }
              , initialBoard =
                    BoardUtils.empty 4 4
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Read
                    , JustInstruction Print
                    , JustInstruction Terminate
                    , BranchAnyDirection Left Right
                    ]
              }
            , { id = "e2f96c5345e5f1f6"
              , name = "Count down"
              , description = [ "> Read a number n from input", "> Output all the numbers from n to 0", "The last input is 0 and should not be printed" ]
              , io =
                    { input = [ 7, 3, 10, 0 ]
                    , output =
                        [ 7, 3, 10 ]
                            |> List.map (List.range 0)
                            |> List.map List.reverse
                            |> List.concat
                    }
              , initialBoard =
                    BoardUtils.empty 7 7
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Decrement
                    , JustInstruction Read
                    , JustInstruction Print
                    , JustInstruction Terminate
                    , BranchAnyDirection Left Right
                    ]
              }
            , { id = "c2003520d988f8d0"
              , name = "Some sums"
              , description = [ "> Read two numbers a and b from input", "> Output a + b", "The last input is 0 and should not be printed" ]
              , io =
                    { input = [ 1, 5, 13, 10, 11, 10, 8, 8, 0 ]
                    , output =
                        [ 6, 23, 21, 16 ]
                    }
              , initialBoard =
                    BoardUtils.empty 7 7
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Decrement
                    , JustInstruction Swap
                    , JustInstruction Read
                    , JustInstruction Print
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "1a3c6d6a80769a07"
              , name = "One minus the other"
              , description = [ "> Read two numbers a and b from input", "> Output a - b", "The last input is 0 and should not be printed" ]
              , io =
                    let
                        input =
                            [ 18, 4, 9, 17, 13, 13, 12, 1, 17, 3 ]
                    in
                    { input = input ++ [ 0 ]
                    , output =
                        input
                            |> listPairs
                            |> List.map (\( a, b ) -> a - b)
                    }
              , initialBoard =
                    BoardUtils.empty 7 7
              , instructionTools =
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
            , { id = "3ee1f15ae601fc94"
              , name = "Powers of two"
              , description = [ "> Read a number n from input", "> Output 2^n ", "The last input is 0 and should not be printed" ]
              , io =
                    let
                        input =
                            [ 1, 4, 3, 2, 5, 6 ]
                    in
                    { input = input ++ [ 0 ]
                    , output =
                        input
                            |> List.map ((^) 2)
                    }
              , initialBoard =
                    BoardUtils.empty 8 8
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Decrement
                    , JustInstruction Swap
                    , JustInstruction Read
                    , JustInstruction Print
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "24c7efb5c41f8f8f"
              , name = "Triangular numbers"
              , description = [ "> Read a number n from input", "> Output n*(n+1)/2 ", "The last input is 0 and should not be printed" ]
              , io =
                    let
                        input =
                            [ 5, 13, 7, 11, 1, 10, 3 ]
                    in
                    { input = input ++ [ 0 ]
                    , output =
                        input
                            |> List.map (\n -> n * (n + 1) // 2)
                    }
              , initialBoard =
                    BoardUtils.empty 8 8
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Decrement
                    , JustInstruction Swap
                    , JustInstruction Read
                    , JustInstruction Print
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "d3c077ea5033222c"
              , name = "Signal amplifier"
              , description = [ "> Read a number x from the input", "> Output x + 10", "The last input is 0 should not be outputed" ]
              , io =
                    let
                        input =
                            [ 24, 145, 49, 175, 166, 94, 38, 90, 165, 211 ]
                    in
                    { input = input ++ [ 0 ]
                    , output =
                        input
                            |> List.map ((+) 10)
                    }
              , initialBoard =
                    BoardUtils.empty 5 5
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Decrement
                    , JustInstruction Swap
                    , JustInstruction Read
                    , JustInstruction Print
                    , JustInstruction (Jump Forward)
                    , JustInstruction PopFromStack
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "bc27b58a0cafb0ba"
              , name = "Multiplier"
              , description = [ "> Read two positive numbers x and y from the input", "> Output x * y", "The last input is 0 should not be outputed" ]
              , io =
                    let
                        input =
                            [ 12, 2, 6, 6, 5, 7, 1, 1, 7, 11, 6, 3 ]
                    in
                    { input = input ++ [ 0 ]
                    , output =
                        input
                            |> listPairs
                            |> List.map (\( x, y ) -> x * y)
                    }
              , initialBoard =
                    BoardUtils.empty 7 7
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Decrement
                    , JustInstruction Swap
                    , JustInstruction SendToBottom
                    , JustInstruction Read
                    , JustInstruction Print
                    , JustInstruction (Jump Forward)
                    , JustInstruction PopFromStack
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "407410b1638112a9"
              , name = "Sequence reverser"
              , description = [ "> Read a sequence of numbers from input", "> Output the sequence in reverse", "The last input is 0 is not part of the sequence" ]
              , io =
                    let
                        input =
                            [ -19, -2, 94, -5, 19, 7, 33, -92, 29, -39 ]
                    in
                    { input = input ++ [ 0 ]
                    , output =
                        input
                            |> List.reverse
                    }
              , initialBoard =
                    BoardUtils.empty 5 5
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Decrement
                    , JustInstruction Swap
                    , JustInstruction Read
                    , JustInstruction Print
                    , JustInstruction (Jump Forward)
                    , JustInstruction PopFromStack
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "1fac7ddba473e99d"
              , name = "Less is more"
              , description = [ "> Read two numbers a and b from the input", "> If a < b output a, otherwise output b", "The last input is 0 is not part of the sequence" ]
              , io =
                    let
                        input =
                            [ 6, 15, 11, 3, 9, 7, 15, 15, 3, 7 ]
                    in
                    { input = input ++ [ 0 ]
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
                    }
              , initialBoard =
                    BoardUtils.empty 8 8
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction Duplicate
                    , JustInstruction Increment
                    , JustInstruction Decrement
                    , JustInstruction Swap
                    , JustInstruction Read
                    , JustInstruction Print
                    , JustInstruction (Jump Forward)
                    , JustInstruction PopFromStack
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "be13bbdd076a586c"
              , name = "Labyrinth 1"
              , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
              , io =
                    { input = []
                    , output = []
                    }
              , initialBoard =
                    BoardUtils.empty 5 5
                        |> BoardUtils.set { x = 2, y = 0 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 4, y = 0 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 1, y = 1 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 2, y = 1 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 2, y = 2 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 1, y = 3 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 4 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 4, y = 4 } Terminate
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    ]
              }
            , { id = "e6d9465e4aacaa0f"
              , name = "Labyrinth 2"
              , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
              , io =
                    { input = []
                    , output = []
                    }
              , initialBoard =
                    BoardUtils.empty 5 5
                        |> BoardUtils.set { x = 4, y = 0 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 1 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 2, y = 2 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 1, y = 3 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 0, y = 4 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 4, y = 4 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 2 } Terminate
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    ]
              }
            , { id = "e81d1f82a8a37103"
              , name = "Labyrinth 3"
              , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
              , io =
                    { input = []
                    , output = []
                    }
              , initialBoard =
                    BoardUtils.empty 5 5
                        |> BoardUtils.set { x = 3, y = 0 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 4, y = 0 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 1 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 2, y = 2 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 4, y = 2 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 0, y = 3 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 1, y = 3 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 0, y = 4 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 2, y = 4 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 2 } Terminate
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction (Jump Forward)
                    ]
              }
            , { id = "e7d5826a6db19981"
              , name = "Labyrinth 4"
              , description = [ "> Terminate the program", "> Don't hit any of the exceptions" ]
              , io =
                    { input = []
                    , output = []
                    }
              , initialBoard =
                    BoardUtils.empty 5 5
                        |> BoardUtils.set { x = 1, y = 0 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 0 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 1, y = 1 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 2, y = 1 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 4, y = 1 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 0, y = 2 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 2 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 0, y = 3 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 1, y = 3 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 2, y = 3 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 4 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 4, y = 4 } (Exception "Don't hit the exceptions")
                        |> BoardUtils.set { x = 3, y = 3 } Terminate
              , instructionTools =
                    [ JustInstruction NoOp
                    , ChangeAnyDirection Right
                    , JustInstruction (Jump Forward)
                    ]
              }
            ]

        levelProgresses : List LevelProgress
        levelProgresses =
            levels
                |> List.map
                    (\level ->
                        { level = level
                        , boardSketch =
                            { boardHistory = History.singleton level.initialBoard
                            , instructionToolbox =
                                { instructionTools = level.instructionTools
                                , selectedIndex = Nothing
                                }
                            }
                        , completed = False
                        }
                    )

        gameState : GameState
        gameState =
            BrowsingLevels Nothing

        model : Model
        model =
            { windowSize = windowSize
            , levelProgresses = levelProgresses
            , gameState = gameState
            }

        cmd : Cmd Msg
        cmd =
            Cmd.batch []
    in
    ( model, cmd )


main : Program WindowSize Model Msg
main =
    Browser.element
        { view = View.view
        , init = init
        , update = Update.update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        windowSizeSubscription =
            Browser.Events.onResize
                (\width height ->
                    Resize
                        { width = width
                        , height = height
                        }
                )
    in
    case model.gameState of
        Executing (ExecutionRunning _ delay) ->
            Sub.batch
                [ windowSizeSubscription
                , Time.every delay (always (ExecutionMsg ExecutionStepOne))
                ]

        _ ->
            windowSizeSubscription


listPairs : List a -> List ( a, a )
listPairs list =
    case list of
        a :: b :: tail ->
            ( a, b ) :: listPairs tail

        _ ->
            []
