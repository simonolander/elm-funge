module Page.Home exposing (Model, Msg, getSession, init, localStorageResponseUpdate, subscriptions, update, view)

import Api.Auth0 as Auth0
import Browser exposing (Document)
import Data.CampaignId as CampaignId
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Json.Encode as Encode
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



-- UPDATE


type alias Msg =
    ()


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

        header =
            View.Header.view model.session

        main =
            column
                [ padding 100
                , spacing 20
                , centerX
                , width (maximum 800 fill)
                ]
                [ titleView
                , link "Levels" (Route.Campaign CampaignId.standard Nothing)
                , link "Blueprints" (Route.Blueprints Nothing)
                , link "Credits" (Route.Campaign "credits" Nothing)
                ]

        body =
            View.Scewn.view
                { north = Just header
                , center = Just main
                , west = Nothing
                , east = Nothing
                , south = Nothing
                }
                |> View.Layout.layout
                |> List.singleton
    in
    { title = "Home"
    , body = body
    }
