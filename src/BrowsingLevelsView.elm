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
import ViewComponents


view : Model -> Html Msg
view model =
    let
        levelProgresses =
            model.levelProgresses

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

        maybeSelectedLevelId =
            Maybe.map (.level >> .id) maybeSelectedLevelProgress

        levelsView =
            viewLevels maybeSelectedLevelId levelProgresses

        sidebarView =
            maybeSelectedLevelProgress
                |> Maybe.map viewSidebar
                |> Maybe.withDefault
                    (column
                        [ width (fillPortion 1)
                        , height fill
                        , padding 20
                        , spacing 20
                        , alignTop
                        , Background.color (rgb 0.05 0.05 0.05)
                        ]
                        []
                    )
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


viewLevels maybeSelectedLevelId levelProgresses =
    let
        viewLevel levelProgress =
            Input.button
                []
                { onPress =
                    if maybeSelectedLevelId == Just levelProgress.level.id then
                        Just (SketchLevelProgress levelProgress.level.id)

                    else
                        Just (SelectLevel levelProgress.level.id)
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
                        , Background.color
                            (if maybeSelectedLevelId == Just levelProgress.level.id then
                                rgba 1 1 1 0.4

                             else
                                rgba 0 0 0 0
                            )
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
            , height fill
            , spacing 20
            , alignTop
            , padding 20
            , scrollbarY
            ]


viewSidebar : LevelProgress -> Element Msg
viewSidebar levelProgress =
    let
        levelNameView =
            ViewComponents.viewTitle []
                levelProgress.level.name

        descriptionView =
            ViewComponents.descriptionTextbox
                []
                levelProgress.level.description

        goToSketchView =
            ViewComponents.textButton
                []
                (Just (SketchLevelProgress levelProgress.level.id))
                "Open Editor"
    in
    column
        [ width (fillPortion 1)
        , height fill
        , padding 20
        , spacing 20
        , alignTop
        , Background.color (rgb 0.05 0.05 0.05)
        ]
        [ levelNameView
        , descriptionView
        , goToSketchView
        ]
