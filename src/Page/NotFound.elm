module Page.NotFound exposing (Model, Msg(..), init, load, subscriptions, update, view)

import ApplicationName exposing (applicationName)
import Browser exposing (Document)
import Data.Session exposing (Session)
import Url
import View.Header
import View.NotFound
import View.Scewn



-- MODEL


type alias Model =
    { session : Session
    }


type Msg
    = InternalMsg InternalMsg
    | SessionMsg Session


type alias InternalMsg =
    ()


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load model =
    ( model, Cmd.none )



-- UPDATE


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
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
            View.Scewn.layout
                { south = Nothing
                , center =
                    Just <|
                        View.NotFound.view
                            { noun = "page"
                            , id = Url.toString model.session.url
                            }
                , east = Nothing
                , west = Nothing
                , north = Just <| View.Header.view model.session
                , modal = Nothing
                }
    in
    { body = [ content ]
    , title = String.concat [ "Not Found", " - ", applicationName ]
    }
