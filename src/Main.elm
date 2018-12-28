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
              , description = "For testing purposes"
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
                    , JustInstruction Print
                    , JustInstruction Read
                    , JustInstruction Add
                    , BranchAnyDirection Left Right
                    , JustInstruction (Jump Forward)
                    ]
              }
            , { id = "42fe70779bd30656"
              , name = "Double the fun"
              , description = "> For each number in in the input, print n * 2\nThe last input is 0 and should not be printed"
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
                    , JustInstruction Print
                    , JustInstruction Read
                    , JustInstruction Terminate
                    , BranchAnyDirection Left Right
                    ]
              }
            , { id = "88c653c6c3a5b5e7"
              , name = "One, two, three"
              , description = "Print the numbers 1, 2, and 3"
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
                    , JustInstruction Print
                    , JustInstruction Read
                    , JustInstruction Terminate
                    , BranchAnyDirection Left Right
                    ]
              }
            , { id = "e2f96c5345e5f1f6"
              , name = "Count down"
              , description = "> Read a number n from input\n> Output all the numbers from n to 0\nThe last input is 0 and should not be printed"
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
                    , JustInstruction Print
                    , JustInstruction Read
                    , JustInstruction Terminate
                    , BranchAnyDirection Left Right
                    ]
              }
            , { id = "c2003520d988f8d0"
              , name = "Some sums"
              , description = "> Read two numbers a and b from input\n> Output a + b\nThe last input is 0 and should not be printed"
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
                    , JustInstruction Print
                    , JustInstruction Read
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "3ee1f15ae601fc94"
              , name = "Powers of two"
              , description = "> Read a number n from input\n> Output 2^n \nThe last input is 0 and should not be printed"
              , io =
                    { input = [ 1, 4, 3, 8, 5, 7, 0 ]
                    , output =
                        [ 2 ^ 1, 2 ^ 4, 2 ^ 3, 2 ^ 8, 2 ^ 5, 2 ^ 7 ]
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
                    , JustInstruction Print
                    , JustInstruction Read
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
                    ]
              }
            , { id = "24c7efb5c41f8f8f"
              , name = "Triangular numbers"
              , description = "> Read a number n from input\n> Output n*(n+1)/2 \nThe last input is 0 and should not be printed"
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
                    , JustInstruction Print
                    , JustInstruction Read
                    , BranchAnyDirection Left Right
                    , JustInstruction Terminate
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
