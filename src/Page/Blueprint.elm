module Page.Blueprint exposing (Model, Msg, getSession, init, localStorageResponseUpdate, subscriptions, update, view)

import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Board as Board
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Session as Session exposing (Session)
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Ports.LocalStorage
import View.Header
import View.Input
import View.Layout
import View.LoadingScreen
import View.Scewn



-- MODEL


type alias Model =
    { session : Session
    , levelId : LevelId
    , width : String
    , height : String
    , error : Maybe String
    }


init : LevelId -> Session -> ( Model, Cmd Msg )
init levelId session =
    let
        model =
            { session = session
            , levelId = levelId
            , width = ""
            , height = ""
            , error = Nothing
            }
    in
    case Dict.get levelId session.levels of
        Just level ->
            initWithLevel level model

        Nothing ->
            ( model, Level.loadFromLocalStorage levelId )


initWithLevel : Level -> Model -> ( Model, Cmd Msg )
initWithLevel level model =
    ( { model
        | levelId = level.id
        , width = String.fromInt (Board.width level.initialBoard)
        , height = String.fromInt (Board.height level.initialBoard)
      }
    , Cmd.none
    )


getSession : Model -> Session
getSession { session } =
    session


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }



-- UPDATE


type Msg
    = ChangedWidth String
    | ChangedHeight String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Dict.get model.levelId model.session.levels of
        Just level ->
            case msg of
                ChangedWidth widthString ->
                    let
                        modelWithWidth =
                            { model | width = widthString }
                    in
                    case String.toInt widthString of
                        Just width ->
                            if width < Level.constraints.minWidth then
                                ( modelWithWidth, Cmd.none )

                            else if width > Level.constraints.maxWidth then
                                ( modelWithWidth, Cmd.none )

                            else
                                let
                                    newLevel =
                                        level.initialBoard
                                            |> Board.withWidth width
                                            |> flip Level.withInitialBoard level

                                    session =
                                        Session.withLevel newLevel model.session

                                    cmd =
                                        Level.saveToLocalStorage newLevel
                                in
                                ( { modelWithWidth | session = session }, cmd )

                        Nothing ->
                            ( modelWithWidth, Cmd.none )

                ChangedHeight heightString ->
                    let
                        modelWithHeight =
                            { model | height = heightString }
                    in
                    case String.toInt heightString of
                        Just height ->
                            if height < Level.constraints.minHeight then
                                ( modelWithHeight, Cmd.none )

                            else if height > Level.constraints.maxHeight then
                                ( modelWithHeight, Cmd.none )

                            else
                                let
                                    newLevel =
                                        level.initialBoard
                                            |> Board.withHeight height
                                            |> flip Level.withInitialBoard level

                                    session =
                                        Session.withLevel newLevel model.session

                                    cmd =
                                        Level.saveToLocalStorage newLevel
                                in
                                ( { modelWithHeight | session = session }, cmd )

                        Nothing ->
                            ( modelWithHeight, Cmd.none )

        Nothing ->
            ( model, Cmd.none )


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate ( key, value ) model =
    let
        onLevel result =
            case result of
                Ok (Just level) ->
                    Session.withLevel level model.session
                        |> setSession model
                        |> initWithLevel level

                Ok Nothing ->
                    ( { model | error = Just ("Level not found: " ++ key) }, Cmd.none )

                Err error ->
                    ( { model | error = Just (Decode.errorToString error) }, Cmd.none )
    in
    ( key, value )
        |> Ports.LocalStorage.oneOf
            [ Level.localStorageResponse onLevel ]
        |> Maybe.withDefault ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            case Dict.get model.levelId model.session.levels of
                Just level ->
                    viewBlueprint level model

                Nothing ->
                    View.LoadingScreen.view "Loading..."

        body =
            content
                |> View.Layout.layout
                |> List.singleton
    in
    { body = body
    , title = "Blueprint"
    }


viewBlueprint : Level -> Model -> Element Msg
viewBlueprint level model =
    let
        header =
            View.Header.view model.session

        west =
            let
                widthInput =
                    View.Input.numericInput []
                        { text = model.width
                        , labelText = "Width"
                        , onChange = ChangedWidth
                        , min = Just Level.constraints.minWidth
                        , max = Just Level.constraints.maxWidth
                        , step = Just 1
                        }

                heightInput =
                    View.Input.numericInput []
                        { text = model.height
                        , labelText = "Height"
                        , onChange = ChangedHeight
                        , min = Just Level.constraints.minHeight
                        , max = Just Level.constraints.maxHeight
                        , step = Just 1
                        }
            in
            column
                [ width fill
                , height fill
                , padding 20
                , spacing 20
                , Background.color (rgb 0.05 0.05 0.05)
                ]
                [ paragraph
                    [ width fill
                    , Font.center
                    ]
                    [ text level.name ]
                , widthInput
                , heightInput
                ]

        center =
            none
    in
    View.Scewn.view
        { north = Just header
        , west = Just west
        , center = Just center
        , east = Nothing
        , south = Nothing
        , modal = Nothing
        }
