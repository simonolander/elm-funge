module View exposing (view)

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
        BrowsingLevels ->
            viewBrowsingLevels model.levelProgresses

        Sketching levelId ->
            let
                maybeLevelProgress =
                    model.levelProgresses
                        |> List.filter (\progress -> progress.level.id == levelId)
                        |> List.head
            in
            case maybeLevelProgress of
                Just levelProgress ->
                    SketchingView.view levelProgress

                Nothing ->
                    Debug.todo "no level"

        Executing executionState ->
            ExecutionView.view executionState


viewBrowsingLevels : List LevelProgress -> Html Msg
viewBrowsingLevels progresses =
    progresses
        |> List.map viewProgress
        |> column [ centerX ]
        |> layout []


viewProgress : LevelProgress -> Element Msg
viewProgress progress =
    Input.button
        []
        { onPress = Just (SelectLevel progress.level.id)
        , label =
            row
                [ Background.color (rgb 0.5 0.5 0.5)
                , padding 20
                , Border.rounded 10
                ]
                [ el [] (text progress.level.name) ]
        }
