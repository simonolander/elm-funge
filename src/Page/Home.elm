module Page.Home exposing (Model, Msg, getSession, init, load, subscriptions, update, view)

import Browser exposing (Document)
import Data.CampaignId as CampaignId
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Extra.Cmd exposing (noCmd)
import Route exposing (Route)
import View.Header
import View.Layout
import View.Scewn
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      }
    , Cmd.none
    )


getSession : Model -> Session
getSession { session } =
    session


load : Model -> ( Model, Cmd Msg )
load =
    noCmd



-- UPDATE


type alias Msg =
    ()


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document msg
view model =
    let
        titleView =
            text "Manick"
                |> el
                    [ centerX
                    , Font.size 42
                    , padding 20
                    ]

        link text route =
            Route.link
                [ width fill ]
                (ViewComponents.textButton [] Nothing text)
                route

        header =
            View.Header.view model.session

        main =
            column
                [ padding 60
                , spacing 20
                , centerX
                , width (maximum 1000 fill)
                ]
                [ titleView
                , link "Levels" (Route.Campaign CampaignId.standard Nothing)

                --                , link "Blueprints" (Route.Blueprints Nothing)
                , link "Credits" Route.Credits
                ]

        footer =
            row
                [ width fill
                ]
                [ Element.link
                    [ padding 20
                    , alignRight
                    , Font.color (rgb 0.25 0.25 0.25)
                    , mouseOver
                        [ Font.color (rgb 0.25 0.25 0.5)
                        ]
                    ]
                    { url = "https://github.com/simonolander/elm-funge"
                    , label = text "1.0.0"
                    }
                ]

        body =
            View.Scewn.view
                { north = Just header
                , center = Just main
                , west = Nothing
                , east = Nothing
                , south = Just footer
                , modal = Nothing
                }
                |> View.Layout.layout
                |> List.singleton
    in
    { title = "Home"
    , body = body
    }
