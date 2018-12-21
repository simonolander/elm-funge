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
            , { id = "Double"
              , name = "Double"
              , io =
                    { input = [ 1, 8, 19, 3, 5, 31, 9, 0 ]
                    , output = [ 2, 16, 38, 6, 10, 62, 18 ]
                    }
              , initialBoard =
                    BoardUtils.empty 10 10
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
            , { id = "92a2c97b-8aea-4fd4-8ffe-7453bd09dc73"
              , name = "Just terminate"
              , io =
                    { input = []
                    , output = []
                    }
              , initialBoard =
                    BoardUtils.empty 3 3
                        |> BoardUtils.set { x = 2, y = 2 } Terminate
              , permittedInstructions = [ NoOp, ChangeDirection Left, ChangeDirection Up, ChangeDirection Right, ChangeDirection Down ]
              }
            , { id = "0c66f4a8-3ce6-442a-85cc-e688f6eaed0b"
              , name = "Hello world"
              , io =
                    { input =
                        List.range (2 ^ 16 - 255) (2 ^ 16 - 1)
                    , output = List.range 0 255
                    }
              , initialBoard = BoardUtils.empty 6 6
              , permittedInstructions = [ NoOp ]
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
            Sketching "Double"

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
