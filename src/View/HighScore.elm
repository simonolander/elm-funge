module View.HighScore exposing (view)

import Data.HighScore exposing (HighScore)
import Element exposing (..)
import Element.Font as Font
import Http exposing (Error(..))
import RemoteData exposing (WebData)
import View.Box
import View.Constant exposing (color)


view : WebData HighScore -> Element msg
view remoteData =
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
    paragraph
        [ Font.center ]
        [ text "Loaded high scores" ]
        |> View.Box.nonInteractive


loading : Element msg
loading =
    paragraph
        [ Font.color color.font.subtle
        , Font.center
        ]
        [ text "Loading high scores..." ]
        |> View.Box.nonInteractive


notAsked : Element msg
notAsked =
    paragraph
        [ Font.color color.font.subtle
        , Font.center
        ]
        [ text "Not asked" ]
        |> View.Box.nonInteractive


failure : Error -> Element msg
failure error =
    let
        errorMessage =
            case error of
                BadUrl message ->
                    message

                Timeout ->
                    "Timeout"

                NetworkError ->
                    "Network error"

                BadStatus status ->
                    String.fromInt status

                BadBody message ->
                    message
    in
    paragraph
        [ Font.color color.font.error
        , Font.center
        ]
        [ text errorMessage ]
        |> View.Box.nonInteractive
