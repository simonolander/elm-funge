module Page.Disclaimer exposing (Model, localStorageResponseUpdate, view)

import Browser exposing (Document)
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Json.Encode as Encode
import Route exposing (Route)
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    }



-- UPDATE


type alias Msg =
    ()


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate ( key, value ) model =
    ( model, Cmd.none )



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

        alphaDisclaimerView =
            paragraph []
                [ text "This puzzle game is in early alpha. "
                , text "Not all the features are available, things will change, and there might be bugs. "
                , text "Your progress will be automatically saved for now, but may be unavailable in future releases. "
                , text "There are also not really any instructions. "
                ]

        tinyInstructionsView =
            paragraph []
                [ text "Every level requires you to write a program to solve. The program must output the expected output and terminate." ]

        featureListView =
            column
                []
                [ text "The current features are: "
                , text "  - ~20 levels"
                , text "  - ~16 instructions"
                , text "  - Save solved levels and last edit to local storage"
                , text "  - Import and export your boards"
                ]

        sourceCodeView =
            paragraph []
                [ text "You can browse the source "
                , newTabLink
                    [ Font.color (rgb 0.5 0.5 1)
                    ]
                    { url = "https://github.com/simonolander/elm-funge"
                    , label = text "here"
                    }
                , text ". If you'd like, leave suggestions and reports in the "
                , newTabLink
                    [ Font.color (rgb 0.5 0.5 1)
                    ]
                    { url = "https://github.com/simonolander/elm-funge/issues"
                    , label = text "issues page"
                    }
                , text "."
                ]

        playButtonView =
            Route.link
                [ width fill ]
                (ViewComponents.textButton [] Nothing "I got it, let's play")
                (Route.Campaign Nothing)

        loginButtonView =
            link
                [ width fill ]
                -- { url = "https://efng.auth.us-east-1.amazoncognito.com/login?response_type=token&client_id=1mu4rr1moo02tobp2m4oe80pn8&redirect_uri=https://efng.simonolander.com"
                { url = "https://efng.auth.us-east-1.amazoncognito.com/login?response_type=token&client_id=1mu4rr1moo02tobp2m4oe80pn8&redirect_uri=http://localhost:3000"
                , label = ViewComponents.textButton [] Nothing "Login"
                }

        body =
            column
                [ padding 100
                , spacing 20
                ]
                [ titleView
                , alphaDisclaimerView
                , tinyInstructionsView
                , featureListView
                , sourceCodeView
                , playButtonView
                , loginButtonView
                ]
                |> layout
                    [ Background.color (rgb 0 0 0)
                    , width fill
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
