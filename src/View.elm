module View exposing (view)

import AlphaDisclaimerView
import Browser
import Draft
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Input as Input
import Execution
import Html exposing (Html)
import Html.Attributes
import LevelProgressUtils
import Levels
import Model exposing (..)


view : Model -> Browser.Document Msg
view model =
    let
        html =
            case model.gameState of
                BrowsingLevels _ ->
                    Levels.view model

                Sketching levelId sketchingState ->
                    case LevelProgressUtils.getLevelProgress levelId model of
                        Just levelProgress ->
                            Draft.view levelProgress sketchingState

                        Nothing ->
                            Levels.view model

                Executing execution executionState ->
                    Execution.view execution executionState

                AlphaDisclaimer ->
                    AlphaDisclaimerView.view
    in
    { title = "EFNG"
    , body = [ html ]
    }
