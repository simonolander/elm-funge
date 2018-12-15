module Main exposing (main)

import BoardUtils
import Browser
import Browser.Events
import History
import Model exposing (..)
import Update
import View


init : ( Model, Cmd Msg )
init =
    let
        levels : List Level
        levels =
            [ { id = "0c66f4a8-3ce6-442a-85cc-e688f6eaed0b"
              , name = "Hello world"
              , cases = [ { input = [], output = [ 1 ] } ]
              , initialBoard = BoardUtils.empty 6 6
              }
            ]

        levelProgresses : List LevelProgress
        levelProgresses =
            levels
                |> List.map
                    (\level ->
                        { level = level
                        , boardSketch =
                            { boardHistory = History.current level.initialBoard
                            }
                        , completed = False
                        }
                    )

        windowSize : WindowSize
        windowSize =
            { width = 0, height = 0 }

        gameState : GameState
        gameState =
            BrowsingLevels

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


main : Program () Model Msg
main =
    Browser.element
        { view = View.view
        , init = \_ -> init
        , update = Update.update
        , subscriptions =
            always
                (Sub.batch
                    [ Browser.Events.onResize
                        (\width height ->
                            Resize
                                { width = width
                                , height = height
                                }
                        )
                    ]
                )
        }
