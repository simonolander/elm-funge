module Page.Credits exposing (Model, Msg, init, load, subscriptions, update, view)

import Basics.Extra exposing (flip, uncurry)
import Browser exposing (Document)
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font exposing (Font)
import Html.Attributes
import Json.Encode as Encode
import View.Header
import View.Layout
import View.Scewn



-- MODEL


type alias Model =
    { session : Session
    }


type alias Msg =
    ()


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    flip Tuple.pair Cmd.none



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate ( key, value ) model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        body =
            column
                [ width (maximum 1000 fill)
                , height fill
                , padding 60
                , spacing 80
                , centerX
                , scrollbars
                ]
                [ section "Credits"
                    (taskAndAuthor
                        [ ( "Development", [ "Simon Olander Sahlén" ] )
                        , ( "Icons", [ "Simon Olander Sahlén" ] )
                        , ( "UX counselling"
                          , [ "Anita Chainiau"
                            , "Anton Håkanson"
                            ]
                          )
                        , ( "Music", [] )
                        ]
                    )
                , section "Source"
                    (link
                        [ centerX
                        , mouseOver [ Font.color (rgb 0.5 0.5 1) ]
                        ]
                        { label = text "https://github.com/simonolander/elm-funge"
                        , url = "https://github.com/simonolander/elm-funge"
                        }
                    )
                , section "Play testing"
                    ([ "Anita Chainiau"
                     , "Anton Håkanson"
                     , "Isac Olander Sahlén"
                     , "Adelie Fournier"
                     , "Benjamin Becquet"
                     , "Erik Bodin"
                     , "Anton Pervorsek"
                     , "Edvin Wallin"
                     , "Carl-Henrik Klåvus"
                     , "Johan von Konow"
                     , "Harald Nicander"
                     , "Karin Aldheimer"
                     , "Malin Molin"
                     ]
                        |> List.map (String.replace " " "\u{00A0}")
                        |> List.sort
                        |> List.map text
                        |> List.map
                            (el
                                [ mouseOver [ Font.color (rgb 0.5 0.5 1) ]
                                , padding 10
                                ]
                            )
                        |> List.intersperse (text " ")
                        |> paragraph [ Font.center ]
                    )
                , section "Special thanks"
                    ([ ( "Zachtronics"
                       , [ text "For making "
                         , link []
                            { label = text "TIS-100"
                            , url = "http://www.zachtronics.com/tis-100/"
                            }
                         , text " and "
                         , link []
                            { label = text "Shenzhen I/O"
                            , url = "http://www.zachtronics.com/shenzhen-io/"
                            }
                         , text ", games I enjoyed and that inspired this work."
                         ]
                       )
                     , ( "Befunge"
                       , [ text "For inspiring the computer language of this game." ]
                       )
                     ]
                        |> List.map (Tuple.mapFirst (text >> el [ Font.size 24, Font.center, width fill ]))
                        |> List.map (Tuple.mapSecond (paragraph [ Font.size 20, Font.center, width fill ]))
                        |> List.map (\( a, b ) -> [ a, b ])
                        |> List.map (column [ width fill, spacing 20 ])
                        |> column [ width fill, spacing 30 ]
                    )
                ]

        content =
            View.Layout.layout <|
                View.Scewn.view
                    { north = Just <| View.Header.view model.session
                    , center = Just body
                    , south = Nothing
                    , east = Nothing
                    , west = Nothing
                    , modal = Nothing
                    }
    in
    { body = [ content ]
    , title = "Credits"
    }


section : String -> Element msg -> Element msg
section title element =
    column
        [ width fill
        , spacing 40
        ]
        [ el
            [ Font.center
            , Font.size 28
            , width fill
            ]
            (text title)
        , element
        ]


taskAndAuthor : List ( String, List String ) -> Element msg
taskAndAuthor tasks =
    let
        top task author =
            row [ width fill, htmlAttribute (Html.Attributes.class "dotted") ]
                [ el
                    [ alignLeft
                    , Background.color (rgb 0 0 0)
                    , paddingEach { left = 0, top = 0, right = 11, bottom = 0 }
                    ]
                    (text task)
                , el
                    [ mouseOver [ Font.color (rgb 0.5 0.5 1) ]
                    , alignRight
                    , Background.color (rgb 0 0 0)
                    , paddingEach { left = 11, top = 0, right = 0, bottom = 0 }
                    ]
                    (text author)
                ]
    in
    tasks
        |> List.map (Tuple.mapSecond List.sort)
        |> List.map
            (\( task, authors ) ->
                case authors of
                    [ author ] ->
                        top task author

                    [] ->
                        top task "null"

                    author :: tail ->
                        tail
                            |> List.map (text >> el [ width fill, Font.alignRight, mouseOver [ Font.color (rgb 0.5 0.5 1) ] ])
                            |> (::) (top task author)
                            |> column [ width fill ]
            )
        |> column [ width fill, centerX, spacing 20 ]
