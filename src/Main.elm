module Main exposing (main)

import Api.AppSync
import BoardUtils
import Browser
import Browser.Events
import Browser.Navigation
import History
import Levels
import LocalStorageUtils
import Maybe.Extra
import Model exposing (..)
import Time
import Update
import Url
import View


init : WindowSize -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init windowSize url navigationKey =
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

        getTokenFromFragment : String -> Maybe String
        getTokenFromFragment fragment =
            fragment
                |> String.split "&"
                |> List.map
                    (\pair ->
                        case String.split "=" pair of
                            [ key, value ] ->
                                Just ( key, value )

                            _ ->
                                Nothing
                    )
                |> Maybe.Extra.values
                |> List.filter (Tuple.first >> (==) "id_token")
                |> List.head
                |> Maybe.map Tuple.second

        token =
            Maybe.andThen getTokenFromFragment url.fragment

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
                , token
                    |> Maybe.map (Api.AppSync.getLevels (always (ApiMsg GetLevelsMsg)))
                    |> Maybe.withDefault Cmd.none
                ]
    in
    ( model, cmd )


main : Program WindowSize Model Msg
main =
    Browser.application
        { view = View.view
        , init = init
        , update = Update.update
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = UrlRequested
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
