module View.Scewn exposing (layout, view)

import Element exposing (..)
import Html
import Maybe.Extra
import View.Layout


type alias Scewn msg =
    { south : Maybe (Element msg)
    , center : Maybe (Element msg)
    , east : Maybe (Element msg)
    , west : Maybe (Element msg)
    , north : Maybe (Element msg)
    , modal : Maybe (Element msg)
    }


view : Scewn msg -> Element msg
view { south, center, east, west, north, modal } =
    let
        middle =
            let
                toRow =
                    row [ width fill, height fill, scrollbars ]
            in
            case ( west, center, east ) of
                ( Just w, Just c, Just e ) ->
                    [ el
                        [ width (maximum 500 (fillPortion 1))
                        , height fill
                        ]
                        w
                    , el
                        [ width (fillPortion 3)
                        , height fill
                        , scrollbars
                        ]
                        c
                    , el
                        [ width (maximum 500 shrink)
                        , height fill
                        ]
                        e
                    ]
                        |> toRow
                        |> Just

                ( Just w, Just c, Nothing ) ->
                    [ el
                        [ width (maximum 500 (fillPortion 1))
                        , height fill
                        ]
                        w
                    , el
                        [ width (fillPortion 3)
                        , height fill
                        , scrollbars
                        ]
                        c
                    ]
                        |> toRow
                        |> Just

                ( Just w, Nothing, Just e ) ->
                    [ el
                        [ width (maximum 500 (fillPortion 1))
                        , height fill
                        ]
                        w
                    , el
                        [ width (maximum 500 (fillPortion 1))
                        , height fill
                        , scrollbars
                        ]
                        e
                    ]
                        |> toRow
                        |> Just

                ( Just w, Nothing, Nothing ) ->
                    Just
                        (el
                            [ width fill
                            , height fill
                            ]
                            w
                        )

                ( Nothing, Just c, Just e ) ->
                    [ el
                        [ width (fillPortion 3)
                        , height fill
                        ]
                        c
                    , el
                        [ width (maximum 500 (fillPortion 1))
                        , height fill
                        ]
                        e
                    ]
                        |> toRow
                        |> Just

                ( Nothing, Just c, Nothing ) ->
                    Just
                        (el
                            [ width fill
                            , height fill
                            ]
                            c
                        )

                ( Nothing, Nothing, Just e ) ->
                    Just
                        (el
                            [ width fill
                            , height fill
                            ]
                            e
                        )

                ( Nothing, Nothing, Nothing ) ->
                    Just
                        (el
                            [ width fill
                            , height fill
                            ]
                            none
                        )

        top =
            Maybe.map
                (el
                    [ width fill
                    ]
                )
                north

        bottom =
            Maybe.map (el [ width fill ]) south

        content =
            [ top
            , middle
            , bottom
            ]
                |> Maybe.Extra.values
                |> column
                    [ width fill
                    , height fill
                    , scrollbars
                    ]
    in
    case modal of
        Just m ->
            el
                [ width fill
                , height fill
                , inFront m
                , scrollbars
                ]
                content

        Nothing ->
            content


layout : Scewn msg -> Html.Html msg
layout =
    view >> View.Layout.layout
