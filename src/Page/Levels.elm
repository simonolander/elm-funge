module Page.Levels exposing (Model, Msg, init, update, view)

import Api
import Browser exposing (Document)
import Data.Level exposing (Level)
import Data.LevelProgress as LevelProgress exposing (LevelProgress)
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Http
import RemoteData exposing (RemoteData(..), WebData)
import Result exposing (Result)
import Route
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    , levels : WebData (List LevelProgress)
    , selectedLevel : Maybe LevelProgress
    }


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , levels = Loading
      , selectedLevel = Nothing
      }
    , Api.getLevels LoadedLevels
    )



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            case model.levels of
                NotAsked ->
                    viewNotAsked

                Loading ->
                    viewLoading

                Failure error ->
                    viewFailure error

                Success levels ->
                    viewSuccess
                        { session = model.session
                        , levels = levels
                        , selectedLevel = model.selectedLevel
                        }
    in
    { title = "Levels"
    , body =
        layout
            [ Background.color (rgb 0 0 0)
            , width fill
            , height fill
            , Font.family
                [ Font.monospace
                ]
            , Font.color (rgb 1 1 1)
            ]
            content
            |> List.singleton
    }


viewNotAsked =
    text "NotAsked"


viewLoading =
    text "Loading"


viewFailure : Http.Error -> Element Msg
viewFailure error =
    case error of
        Http.BadUrl string ->
            "Bad url: "
                ++ string
                |> text

        Http.Timeout ->
            "Timeout"
                |> text

        Http.NetworkError ->
            "Network error"
                |> text

        Http.BadStatus int ->
            "Bad status: "
                ++ String.fromInt int
                |> text

        Http.BadBody string ->
            "Bad body: "
                ++ string
                |> text


viewSuccess :
    { session : Session
    , levels : List LevelProgress
    , selectedLevel : Maybe LevelProgress
    }
    -> Element Msg
viewSuccess { session, levels, selectedLevel } =
    let
        levelsView =
            viewLevels selectedLevel levels

        sidebarView =
            selectedLevel
                |> Maybe.map viewSidebar
                |> Maybe.withDefault
                    (column
                        [ width (fillPortion 1)
                        , height fill
                        , padding 20
                        , spacing 20
                        , alignTop
                        , Background.color (rgb 0.05 0.05 0.05)
                        ]
                        [ el
                            [ centerX
                            , Font.size 32
                            ]
                            (text "EFNG")
                        , el
                            [ centerX
                            ]
                            (text "Select a level")
                        ]
                    )
    in
    row
        [ width fill
        , height fill
        ]
        [ sidebarView, levelsView ]


viewLevels : Maybe LevelProgress -> List LevelProgress -> Element Msg
viewLevels maybeSelectedLevel levelProgresses =
    let
        viewLevel levelProgress =
            let
                selected =
                    maybeSelectedLevel
                        |> Maybe.map (.level >> .id >> (==) levelProgress.level.id)
                        |> Maybe.withDefault False

                buttonAttributes =
                    if LevelProgress.isSolved levelProgress then
                        [ htmlAttribute
                            (Html.Attributes.class "solved")
                        ]

                    else
                        []
            in
            Input.button
                buttonAttributes
                { onPress =
                    if selected then
                        Just OpenDraftClicked

                    else
                        Just (SelectLevel levelProgress)
                , label =
                    column
                        [ padding 20
                        , Border.width 3
                        , width (px 256)
                        , spaceEvenly
                        , height (px 181)
                        , mouseOver
                            [ Background.color (rgba 1 1 1 0.5)
                            ]
                        , Background.color
                            (if selected then
                                rgba 1 1 1 0.4

                             else
                                rgba 0 0 0 0
                            )
                        ]
                        [ el [ centerX, Font.center ] (paragraph [] [ text levelProgress.level.name ])
                        , el [ centerX ]
                            (paragraph
                                [ Font.color
                                    (rgb 0.2 0.2 0.2)
                                ]
                                [ text levelProgress.level.id ]
                            )
                        ]
                }
    in
    levelProgresses
        |> List.map viewLevel
        |> wrappedRow
            [ width (fillPortion 3)
            , height fill
            , spacing 20
            , alignTop
            , padding 20
            , scrollbarY
            ]


viewSidebar : LevelProgress -> Element Msg
viewSidebar levelProgress =
    let
        levelNameView =
            ViewComponents.viewTitle []
                levelProgress.level.name

        descriptionView =
            ViewComponents.descriptionTextbox
                []
                levelProgress.level.description

        solvedStatusView =
            row
                [ centerX ]
                [ el
                    [ width fill
                    ]
                    (if LevelProgress.isSolved levelProgress then
                        text "Solved"

                     else
                        text "Not solved"
                    )
                ]

        goToSketchView =
            ViewComponents.textButton
                []
                (Just OpenDraftClicked)
                "Open Editor"
    in
    column
        [ width (fillPortion 1)
        , height fill
        , padding 20
        , spacing 20
        , alignTop
        , Background.color (rgb 0.05 0.05 0.05)
        ]
        [ levelNameView
        , solvedStatusView
        , descriptionView
        , goToSketchView
        ]



-- UPDATE


type Msg
    = SelectLevel LevelProgress
    | LoadedLevels (Result Http.Error (List Level))
    | OpenDraftClicked


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectLevel selectedLevel ->
            ( { model
                | selectedLevel = Just selectedLevel
              }
            , Cmd.none
            )

        OpenDraftClicked ->
            ( model
            , Route.replaceUrl model.session.key Route.Home
            )

        LoadedLevels result ->
            case result of
                Ok levels ->
                    ( { model
                        | levels =
                            levels
                                |> List.sortBy .index
                                |> List.map
                                    (\level ->
                                        { level = level, drafts = [] }
                                    )
                                |> Success
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model | levels = Failure error }, Cmd.none )
