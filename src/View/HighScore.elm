module View.HighScore exposing (view)

import Data.GetError as DetailedHttpError exposing (GetError)
import Data.HighScore exposing (HighScore)
import Dict
import Element exposing (..)
import Element.Font as Font
import RemoteData exposing (RemoteData)
import View.Box
import View.Constant exposing (color)


view : RemoteData GetError HighScore -> Element msg
view remoteData =
    --    let
    --        remoteData =
    --            RemoteData.Success
    --                { levelId = "12380f983038a019"
    --                , numberOfSteps =
    --                    Dict.fromList
    --                        [ ( 0, 51 )
    --                        , ( 1, 34 )
    --                        , ( 6, 13 )
    --                        , ( 9, 57 )
    --                        ]
    --                , numberOfInstructions =
    --                    Dict.fromList
    --                        [ ( 0, 7 )
    --                        , ( 1, 94 )
    --                        , ( 9, 45 )
    --                        ]
    --                }
    --    in
    case remoteData of
        RemoteData.NotAsked ->
            notAsked

        RemoteData.Loading ->
            loading

        RemoteData.Failure error ->
            failure error

        RemoteData.Success highScore ->
            success highScore


success : HighScore -> Element msg
success highScore =
    if Dict.isEmpty highScore.numberOfInstructions then
        View.Box.simpleNonInteractive "No high scores"

    else
        let
            numberOfStepsView =
                highScore.numberOfSteps
                    |> Dict.toList
                    |> List.sortBy Tuple.first
                    |> List.map
                        (\( key, value ) ->
                            row
                                [ width fill
                                , spacing 20
                                ]
                                [ text (String.fromInt key)
                                , text (String.fromInt value)
                                ]
                        )
                    |> (::)
                        (paragraph []
                            [ text "Number of steps:"
                            ]
                        )
                    |> column
                        [ width fill ]

            numberOfInstructionsView =
                highScore.numberOfInstructions
                    |> Dict.toList
                    |> List.sortBy Tuple.first
                    |> List.map
                        (\( key, value ) ->
                            row
                                [ width fill
                                , spacing 20
                                ]
                                [ text (String.fromInt key)
                                , text (String.fromInt value)
                                ]
                        )
                    |> (::)
                        (paragraph []
                            [ text "Number of instructions:"
                            ]
                        )
                    |> column
                        [ width fill ]
        in
        [ numberOfInstructionsView
        , numberOfStepsView
        ]
            |> column
                [ spacing 20 ]
            |> View.Box.nonInteractive


loading : Element msg
loading =
    View.Box.simpleLoading "Loading high scores"


notAsked : Element msg
notAsked =
    View.Box.simpleNonInteractive "Not asked"


failure : GetError -> Element msg
failure error =
    let
        errorMessage =
            DetailedHttpError.toString error
    in
    paragraph
        [ Font.color color.font.error
        , Font.center
        ]
        [ text errorMessage ]
        |> View.Box.nonInteractive
