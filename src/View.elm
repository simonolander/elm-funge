module View exposing (view)

import AlphaDisclaimerView
import BrowsingLevelsView
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Input as Input
import ExecutionView
import Html exposing (Html)
import Html.Attributes
import Model exposing (..)
import SketchingView


view : Model -> Html Msg
view model =
    case model.gameState of
        BrowsingLevels _ ->
            BrowsingLevelsView.view model

        Sketching levelId ->
            let
                maybeLevelProgress : Maybe LevelProgress
                maybeLevelProgress =
                    model.levelProgresses
                        |> List.filter (\progress -> progress.level.id == levelId)
                        |> List.head
            in
            case maybeLevelProgress of
                Just levelProgress ->
                    SketchingView.view levelProgress

                Nothing ->
                    text "TODO: couldn't find level progress"
                        |> layout []

        Executing executionState ->
            ExecutionView.view executionState

        AlphaDisclaimer ->
            AlphaDisclaimerView.view
