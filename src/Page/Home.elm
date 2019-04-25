module Page.Home exposing (Model, Msg, getSession, init, subscriptions, update, view)

import Api.Auth0 as Auth0
import Browser exposing (Document)
import Data.CampaignId as CampaignId
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Route exposing (Route)
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
            text "EFNG"
                |> el
                    [ centerX
                    , Font.size 32
                    ]

        link text route =
            Route.link
                [ width fill ]
                (ViewComponents.textButton [] Nothing text)
                route

        body =
            column
                [ padding 100
                , spacing 20
                , centerX
                , width (maximum 800 fill)
                ]
                [ titleView
                , link "Levels" (Route.Campaign CampaignId.standard Nothing)
                , Element.link
                    [ width fill ]
                    { label = ViewComponents.textButton [] Nothing "Login"
                    , url = Auth0.login
                    }
                , Element.link
                    [ width fill ]
                    { label = ViewComponents.textButton [] Nothing "Logout"
                    , url = Auth0.logout
                    }
                , link "Blueprints" (Route.Blueprints Nothing)
                , link "Credits" (Route.Campaign "credits" Nothing)
                ]
                |> layout
                    [ width fill
                    , height fill
                    , Font.family
                        [ Font.monospace
                        ]
                    , Font.color (rgb 1 1 1)
                    ]
                |> List.singleton
    in
    { title = "Home"
    , body = body
    }
