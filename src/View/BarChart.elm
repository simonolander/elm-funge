module View.BarChart exposing (test, view)

{-| This module shows how to build a simple bar chart.
-}

import Axis
import Color exposing (white)
import Dict
import Extra.Maybe
import Html
import List.Extra
import Scale exposing (BandScale, ContinuousScale)
import TypedSvg exposing (g, polygon, rect, style, svg, text_)
import TypedSvg.Attributes exposing (class, color, points, textAnchor, transform, viewBox)
import TypedSvg.Attributes.InPx exposing (height, width, x, y)
import TypedSvg.Core exposing (Svg, text)
import TypedSvg.Types exposing (AnchorAlignment(..), Transform(..))


timeSeries : List ( Int, Int )
timeSeries =
    [ ( 1, 60 - 0 )
    , ( 2, 60 - 1 )
    , ( 16, 60 - 2 )
    , ( 21, 60 - 3 )
    , ( 30, 60 - 4 )
    , ( 52, 60 - 5 )
    , ( 65, 60 - 6 )
    , ( 66, 60 - 7 )
    , ( 84, 60 - 8 )
    , ( 90, 60 - 9 )
    , ( 94, 60 - 10 )
    , ( 111, 60 - 11 )
    , ( 138, 60 - 12 )
    , ( 154, 60 - 13 )
    , ( 159, 60 - 14 )
    , ( 161, 60 - 15 )
    , ( 174, 60 - 16 )
    , ( 230, 60 - 17 )
    , ( 231, 60 - 18 )
    , ( 247, 60 - 19 )
    , ( 252, 60 - 20 )
    , ( 263, 60 - 21 )
    , ( 266, 60 - 22 )
    , ( 268, 60 - 23 )
    , ( 271, 60 - 24 )
    , ( 393, 60 - 25 )
    , ( 401, 60 - 26 )
    , ( 443, 60 - 27 )
    , ( 450, 60 - 28 )
    , ( 454, 60 - 29 )
    , ( 457, 60 - 30 )
    , ( 483, 60 - 31 )
    , ( 495, 60 - 32 )
    , ( 510, 60 - 33 )
    , ( 525, 60 - 34 )
    , ( 526, 60 - 35 )
    , ( 580, 60 - 36 )
    , ( 588, 60 - 37 )
    , ( 591, 60 - 38 )
    , ( 639, 60 - 39 )
    , ( 642, 60 - 40 )
    , ( 654, 60 - 41 )
    , ( 690, 60 - 42 )
    , ( 705, 60 - 43 )
    , ( 726, 60 - 44 )
    , ( 743, 60 - 45 )
    , ( 747, 60 - 46 )
    , ( 771, 60 - 47 )
    , ( 819, 60 - 48 )
    , ( 824, 60 - 49 )
    , ( 826, 60 - 50 )
    , ( 847, 60 - 51 )
    , ( 861, 60 - 52 )
    , ( 874, 60 - 53 )
    , ( 924, 60 - 54 )
    , ( 949, 60 - 55 )
    , ( 957, 60 - 56 )
    , ( 965, 60 - 57 )
    , ( 997, 60 - 58 )
    , ( 998, 60 - 59 )
    , ( 999, 60 - 60 )
    ]


myScore =
    List.Extra.getAt 20 timeSeries
        |> Maybe.map Tuple.first


maxNumberOfColumns : Int
maxNumberOfColumns =
    17


scaleFactor : Float
scaleFactor =
    0.5


w : Float
w =
    900 * scaleFactor


h : Float
h =
    450 * scaleFactor


paddingLeft : Float -> Float
paddingLeft maxRange =
    maxRange
        |> floor
        |> String.fromInt
        |> String.length
        |> toFloat
        |> (*) 26
        |> (+) 40
        |> (*) scaleFactor


paddingRight : Float
paddingRight =
    20 * scaleFactor


paddingTop : Float
paddingTop =
    20 * scaleFactor


paddingBottom : Float
paddingBottom =
    70 * scaleFactor


xScale :
    { domain : List Int
    , paddingLeft : Float
    , paddingRight : Float
    }
    -> BandScale Int
xScale p =
    let
        config =
            if List.length p.domain > 8 then
                { paddingInner = 0.0, paddingOuter = 0.2, align = 0.5 }

            else
                { paddingInner = 0.3, paddingOuter = 0.2, align = 0.5 }
    in
    Scale.band config ( 0, w - p.paddingLeft - p.paddingRight ) p.domain


yScale : ( Float, Float ) -> ContinuousScale Float
yScale =
    Scale.linear ( h - paddingBottom - paddingTop, 0 )


dateFormat : Int -> String
dateFormat =
    String.fromInt


xAxis :
    { domain : List Int
    , paddingLeft : Float
    , paddingRight : Float
    }
    -> Svg msg
xAxis p =
    Axis.bottom [] (Scale.toRenderable dateFormat (xScale p))


yAxis : ( Float, Float ) -> Svg msg
yAxis range =
    Axis.left [ Axis.tickCount (min 5 (floor (Tuple.second range))), Axis.tickFormat (floor >> String.fromInt) ] (yScale range)


column : ( Float, Float ) -> BandScale Int -> ( Int, ( Int, Bool ) ) -> Svg msg
column range scale ( xValue, ( yValue, marked ) ) =
    g [ class [ "column" ] ]
        [ rect
            [ x <| Scale.convert scale xValue
            , y <| Scale.convert (yScale range) (toFloat yValue)
            , width <| Scale.bandwidth scale
            , height <| h - Scale.convert (yScale range) (toFloat yValue) - paddingBottom - paddingTop
            ]
            []
        , text_
            [ x <| Scale.convert (Scale.toRenderable dateFormat scale) xValue
            , y <| Scale.convert (yScale range) (toFloat yValue) - 8
            , textAnchor AnchorMiddle
            ]
            [ text <| String.fromInt yValue ]
        , if marked then
            polygon
                [ class [ "me" ]
                , points
                    [ ( (Scale.convert scale xValue + Scale.bandwidth scale / 2) - 7.071, Scale.convert (yScale range) (toFloat yValue) - 20 )
                    , ( (Scale.convert scale xValue + Scale.bandwidth scale / 2) + 7.071, Scale.convert (yScale range) (toFloat yValue) - 20 )
                    , ( Scale.convert scale xValue + Scale.bandwidth scale / 2, Scale.convert (yScale range) (toFloat yValue) - 10 )
                    ]
                ]
                []

          else
            text ""
        ]


view : Maybe Int -> List ( Int, Int ) -> Html.Html msg
view mine scores =
    let
        markedScores : List ( Int, ( Int, Bool ) )
        markedScores =
            scores
                |> List.foldl (\( x, y ) dict -> Dict.update x (Maybe.withDefault 0 >> (+) y >> Just) dict) Dict.empty
                |> Extra.Maybe.update mine (Maybe.withDefault 1 >> Just)
                |> Dict.toList
                |> List.sortBy Tuple.first
                |> List.map (\( k, v ) -> ( k, ( v, Maybe.withDefault False (Maybe.map ((==) k) mine) ) ))
                |> (\list ->
                        if List.length list <= maxNumberOfColumns then
                            list

                        else
                            case List.Extra.findIndex (Tuple.second >> Tuple.second) list of
                                Just index ->
                                    list |> List.drop (index - maxNumberOfColumns // 2 - max 0 (maxNumberOfColumns // 2 - List.length list + index + 1)) |> List.take maxNumberOfColumns

                                Nothing ->
                                    List.take maxNumberOfColumns list
                   )

        domain =
            List.map Tuple.first markedScores

        range =
            ( 0
            , markedScores
                |> List.map (Tuple.second >> Tuple.first)
                |> List.maximum
                |> Maybe.withDefault 0
                |> toFloat
                |> (*) 1.1
            )

        padLeft =
            paddingLeft (Tuple.second range)
    in
    svg [ viewBox 0 0 w h ]
        [ style [] [ text """
            .column rect { fill: transparent; stroke: white; stroke-width: 3; }
            .column:hover rect { fill: white; }
            .column text { display: none; fill: white; }
            .column:hover text { display: inline; }
            .domain { stroke: white; stroke-width: 3; shape-rendering: crispEdges; }
            .tick line { stroke: white; stroke-width: 2; }
            .tick text { font-family: monospace; fill: white; font-size: 20px }
            .column .me { fill: white }
            .column:hover .me { display: none }
          """ ]
        , g [ transform [ Translate (padLeft - 1) (h - paddingBottom) ] ]
            [ xAxis { domain = domain, paddingLeft = padLeft, paddingRight = paddingRight } ]
        , g
            [ transform [ Translate (padLeft - 1) paddingTop ]
            , color white
            ]
            [ yAxis range ]
        , g [ transform [ Translate (padLeft - 0.5) (paddingTop + 0.5) ], class [ "series" ] ] <|
            List.map (column range (xScale { domain = domain, paddingLeft = padLeft, paddingRight = paddingRight })) markedScores
        ]


test : Html.Html msg
test =
    view myScore timeSeries
