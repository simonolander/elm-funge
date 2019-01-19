module Main exposing (main)

import BoardUtils
import Browser
import Browser.Events
import History
import Levels
import LocalStorageUtils
import Model exposing (..)
import Time
import Update
import View


init : WindowSize -> ( Model, Cmd Msg )
init windowSize =
    let
        levels : List Level
        levels =
            Levels.levels

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
                        , solved = False
                        }
                    )

        gameState : GameState
        gameState =
            AlphaDisclaimer

        funnelState =
            LocalStorageUtils.initialState

        model : Model
        model =
            { windowSize = windowSize
            , levelProgresses = levelProgresses
            , gameState = gameState
            , funnelState = funnelState
            }

        cmd : Cmd Msg
        cmd =
            let
                getLevelProgressSolvedCmd =
                    levels
                        |> List.map .id
                        |> List.map (\id -> LocalStorageUtils.getLevelSolved id funnelState)
                        |> Cmd.batch

                getLevelProgressBoards =
                    levels
                        |> List.map .id
                        |> List.map (\id -> LocalStorageUtils.getBoard id funnelState)
                        |> Cmd.batch
            in
            Cmd.batch
                [ getLevelProgressSolvedCmd
                , getLevelProgressBoards
                ]
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

        localStorageProcessSubscription =
            LocalStorageUtils.subscriptions (LocalStorageMsg << LocalStorageProcess) model
    in
    case model.gameState of
        Executing _ (ExecutionRunning delay) ->
            Sub.batch
                [ windowSizeSubscription
                , localStorageProcessSubscription
                , Time.every delay (always (ExecutionMsg ExecutionStepOne))
                ]

        _ ->
            Sub.batch
                [ windowSizeSubscription
                , localStorageProcessSubscription
                ]
