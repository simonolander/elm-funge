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
import LevelProgressUtils
import Model exposing (..)
import SketchingView


view : Model -> Html Msg
view model =
    case model.gameState of
        BrowsingLevels _ ->
            BrowsingLevelsView.view model

        Sketching levelId sketchingState ->
            case LevelProgressUtils.getLevelProgress levelId model of
                Just levelProgress ->
                    SketchingView.view levelProgress sketchingState

                Nothing ->
                    BrowsingLevelsView.view model

        Executing executionState ->
            ExecutionView.view executionState

        AlphaDisclaimer ->
            AlphaDisclaimerView.view
