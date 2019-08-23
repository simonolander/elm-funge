module View.HighScore exposing (view)

import Data.GetError as DetailedHttpError exposing (GetError)
import Data.HighScore exposing (HighScore)
import Data.Solution exposing (Solution)
import Dict
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import RemoteData exposing (RemoteData)
import View.BarChart as BarChart
import View.Box
import View.Constant exposing (color)


view : List Solution -> RemoteData GetError HighScore -> Element msg
view solutions remoteData =
    case remoteData of
        RemoteData.NotAsked ->
            notAsked

        RemoteData.Loading ->
            loading

        RemoteData.Failure error ->
            failure error

        RemoteData.Success highScore ->
            if List.isEmpty solutions && Dict.isEmpty highScore.numberOfInstructions then
                View.Box.simpleNonInteractive "No high scores"

            else
                column
                    [ width fill
                    , spacing 20
                    ]
                    [ graph
                        { title = "Number of steps"
                        , personalBest =
                            solutions
                                |> List.map (.score >> .numberOfSteps)
                                |> List.minimum
                        , data = Dict.toList highScore.numberOfSteps
                        }
                    , graph
                        { title = "Number of instructions"
                        , personalBest =
                            solutions
                                |> List.map (.score >> .numberOfInstructions)
                                |> List.minimum
                        , data = Dict.toList highScore.numberOfInstructions
                        }
                    ]


graph : { title : String, personalBest : Maybe Int, data : List ( Int, Int ) } -> Element msg
graph { title, personalBest, data } =
    column
        [ width fill
        , spacing 10
        , paddingEach { left = 0, top = 10, right = 0, bottom = 0 }
        , Border.width 3
        , Border.color (rgb 1 1 1)
        ]
        [ paragraph
            [ width fill
            , Font.center
            ]
            [ text title ]
        , html (BarChart.view personalBest data)
        ]


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
