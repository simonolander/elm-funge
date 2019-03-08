module View exposing (view)

import AlphaDisclaimerView
import Browser
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


view : Model -> Browser.Document Msg
view model =
    let
        html =
            case model.gameState of
                BrowsingLevels _ ->
                    BrowsingLevelsView.view model

                Sketching levelId sketchingState ->
                    case LevelProgressUtils.getLevelProgress levelId model of
                        Just levelProgress ->
                            SketchingView.view levelProgress sketchingState

                        Nothing ->
                            BrowsingLevelsView.view model

                Executing execution executionState ->
                    ExecutionView.view execution executionState

                AlphaDisclaimer ->
                    AlphaDisclaimerView.view
    in
    { title = "EFNG"
    , body = [ html ]
    }
