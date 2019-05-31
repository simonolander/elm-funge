module Page.Login exposing (Model, Msg, getSession, init, subscriptions, update, view)

import Browser exposing (Document)
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    , username : String
    , password : String
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , username = ""
      , password = ""
      }
    , Cmd.none
    )


getSession : Model -> Session
getSession { session } =
    session



-- UPDATE


type Msg
    = UsernameChanged String
    | PasswordChanged String
    | LoginClicked


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UsernameChanged username ->
            ( { model | username = username }, Cmd.none )

        PasswordChanged password ->
            ( { model | password = password }, Cmd.none )

        LoginClicked ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            column
                [ width (maximum 800 fill)
                , centerX
                , spacing 20
                , padding 50
                ]
                [ text "Login"
                , Input.username
                    [ width fill
                    , Background.color (rgb 0.1 0.1 0.1)
                    ]
                    { onChange = UsernameChanged
                    , text = model.username
                    , placeholder = Nothing
                    , label = Input.labelAbove [] (text "Username")
                    }
                , Input.currentPassword
                    [ width fill
                    , Background.color (rgb 0.1 0.1 0.1)
                    ]
                    { onChange = PasswordChanged
                    , text = model.password
                    , placeholder = Nothing
                    , label = Input.labelAbove [] (text "password")
                    , show = False
                    }
                , ViewComponents.textButton
                    []
                    (Just LoginClicked)
                    "Login"
                ]
                |> layout
                    [ width fill
                    , height fill
                    , Font.color (rgb 1 1 1)
                    , Font.family [ Font.monospace ]
                    ]
    in
    { body = [ content ]
    , title = "Login"
    }
