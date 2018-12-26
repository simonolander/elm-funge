module BrowsingLevelsView exposing (view)

import Array exposing (Array)
import BoardUtils
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import History
import Html exposing (Html)
import Html.Attributes
import Model exposing (..)


view : Model -> Html Msg
view model =
    let
        levelProgresses =
            model.levelProgresses

        maybeSelectedLevelProgress : Maybe LevelProgress
        maybeSelectedLevelProgress =
            case model.gameState of
                BrowsingLevels maybeLevelId ->
                    maybeLevelId
                        |> Maybe.andThen
                            (\levelId ->
                                levelProgresses
                                    |> List.filter (\levelProgress -> levelProgress.level.id == levelId)
                                    |> List.head
                            )

                _ ->
                    Nothing

        levelsView =
            viewLevels levelProgresses

        sidebarView =
            maybeSelectedLevelProgress
                |> Maybe.map viewSidebar
                |> Maybe.withDefault none
    in
    layout
        [ Background.color (rgb 0 0 0)
        , width fill
        , height fill
        , Font.family
            [ Font.monospace
            ]
        , Font.color (rgb 1 1 1)
        ]
        (row
            [ width fill
            , height fill
            ]
            [ sidebarView, levelsView ]
        )


viewLevels levelProgresses =
    let
        viewLevel levelProgress =
            Input.button
                []
                { onPress = Just (SelectLevel levelProgress.level.id)
                , label =
                    column
                        [ padding 20
                        , Border.width 3
                        , width (px 256)
                        , spaceEvenly
                        , height (px 181)
                        , mouseOver
                            [ Background.color (rgba 1 1 1 0.5)
                            ]
                        ]
                        [ el [ centerX, Font.center ] (paragraph [] [ text levelProgress.level.name ])
                        , el [ centerX ]
                            (paragraph
                                [ Font.color
                                    (rgb 0.2 0.2 0.2)
                                ]
                                [ text levelProgress.level.id ]
                            )
                        ]
                }
    in
    levelProgresses
        |> List.map viewLevel
        |> wrappedRow
            [ width (fillPortion 3)
            , spacing 20
            , alignTop
            , padding 20
            ]


viewSidebar : LevelProgress -> Element Msg
viewSidebar levelProgress =
    let
        levelNameView =
            el [width fill, Font.center, Font.size 24] (text levelProgress.level.name)

        goToSketchView =
            Input.button
                [ width fill
                , Border.width 3
                , padding 10
                , mouseOver [
                    Background.color (rgb 0.5 0.5 0.5)
                ]
                ]
                { onPress = Just (SketchLevelProgress levelProgress.level.id)
                , label = el [ Font.center, width fill ] (text "Open Editor")
                }
    in
    column
        [ width (fillPortion 1)
        , padding 20
        , spacing 20
        , alignTop
        ]
        [ levelNameView
        , goToSketchView
        ]
