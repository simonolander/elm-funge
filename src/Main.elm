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
            [ { id = "test"
              , name = "test"
              , description = "For testing purposes"
              , io =
                    { input = List.range 980 1020
                    , output = []
                    }
              , initialBoard =
                    BoardUtils.empty 3 3
                        |> BoardUtils.set { x = 2, y = 2 } Terminate
              , permittedInstructions =
                    [ NoOp
                    , ChangeDirection Left
                    , ChangeDirection Up
                    , ChangeDirection Right
                    , ChangeDirection Down
                    , Duplicate
                    , Increment
                    , Print
                    , Read
                    , Add
                    ]
              }
            , { id = "f10670c5-1a35-448c-81eb-9ef8615af054"
              , name = "Double the fun"
              , description = "> For each number in in the input, print n * 2\nThe last input is 0 and should not be printed"
              , io =
                    { input = [ 1, 8, 19, 3, 5, 31, 9, 0 ]
                    , output = [ 2, 16, 38, 6, 10, 62, 18 ]
                    }
              , initialBoard =
                    BoardUtils.empty 4 4
              , permittedInstructions =
                    [ NoOp
                    , ChangeDirection Left
                    , ChangeDirection Up
                    , ChangeDirection Right
                    , ChangeDirection Down
                    , Duplicate
                    , Add
                    , Print
                    , Read
                    , Terminate
                    , Branch Left Right
                    ]
              }
            , { id = "d4d0a3ac-5531-4146-88d7-c67985b0e6fc"
              , name = "One, two, three"
              , description = "Print the numbers 1, 2, and 3"
              , io =
                    { input = []
                    , output = [ 1, 2, 3 ]
                    }
              , initialBoard =
                    BoardUtils.empty 4 4
              , permittedInstructions =
                    [ NoOp
                    , ChangeDirection Left
                    , ChangeDirection Up
                    , ChangeDirection Right
                    , ChangeDirection Down
                    , Duplicate
                    , Increment
                    , Print
                    , Read
                    , Terminate
                    , Branch Left Right
                    ]
              }
            , { id = "eca91b31-01a0-4adf-b453-7f6d5d0bab5b"
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
              , permittedInstructions =
                    [ NoOp
                    , ChangeDirection Left
                    , ChangeDirection Up
                    , ChangeDirection Right
                    , ChangeDirection Down
                    , Duplicate
                    , Decrement
                    , Print
                    , Read
                    , Terminate
                    , Branch Left Right
                    ]
              }
            , { id = "246ea0f5-fc1f-43de-b061-a55d2f749336s"
              , name = "Some sums"
              , description = "> Read two numbers a and b from input\n> Output a + b\nThe last input is 0 and should not be printed"
              , io =
                    { input = [ 1, 5, 13, 10, 11, 10, 8, 8, 0 ]
                    , output =
                        [ 6, 23, 21, 16 ]
                    }
              , initialBoard =
                    BoardUtils.empty 7 7
              , permittedInstructions =
                    [ NoOp
                    , ChangeDirection Left
                    , ChangeDirection Up
                    , ChangeDirection Right
                    , ChangeDirection Down
                    , Duplicate
                    , Increment
                    , Decrement
                    , Swap
                    , Print
                    , Read
                    , Branch Down Right
                    , Branch Left Right
                    , Terminate
                    ]
              }
            , { id = "87e1f6b0-9cc1-4809-8a62-219507cee40a"
              , name = "Powers of two"
              , description = "> Read a number n from input\n> Output 2^n \nThe last input is 0 and should not be printed"
              , io =
                    { input = [ 1, 4, 3, 8, 5, 7, 0 ]
                    , output =
                        [ 2 ^ 1, 2 ^ 4, 2 ^ 3, 2 ^ 8, 2 ^ 5, 2 ^ 7 ]
                    }
              , initialBoard =
                    BoardUtils.empty 8 8
              , permittedInstructions =
                    [ NoOp
                    , ChangeDirection Left
                    , ChangeDirection Up
                    , ChangeDirection Right
                    , ChangeDirection Down
                    , Duplicate
                    , Increment
                    , Decrement
                    , Swap
                    , Print
                    , Read
                    , Branch Down Right
                    , Branch Left Right
                    , Terminate
                    ]
              }
            , { id = "872e1d003c2ab606"
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
              , permittedInstructions =
                    [ NoOp
                    , ChangeDirection Left
                    , ChangeDirection Up
                    , ChangeDirection Right
                    , ChangeDirection Down
                    , Duplicate
                    , Increment
                    , Decrement
                    , Swap
                    , Print
                    , Read
                    , Branch Down Right
                    , Branch Left Right
                    , Terminate
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
                            , selectedInstruction = Nothing
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
