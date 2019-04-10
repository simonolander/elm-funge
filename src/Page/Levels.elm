module Page.Levels exposing (Model, Msg, getSession, init, subscriptions, update, view)

import Api
import Browser exposing (Document)
import Data.Draft as Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.LevelProgress as LevelProgress exposing (LevelProgress)
import Data.Session as Session exposing (Session)
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Http
import Json.Decode as Decode
import Ports.LocalStorage as LocalStorage exposing (Key)
import Random
import Result exposing (Result)
import Route
import ViewComponents



-- MODEL


type alias LoadingLevelsModel =
    { session : Session
    }


type alias LoadingDraftsModel =
    { session : Session
    , levels : List Level
    }


type alias LoadedModel =
    { session : Session
    , levels : Dict LevelId LevelProgress
    , selectedLevel : Maybe LevelProgress
    }


type alias ErrorModel =
    { session : Session
    , error : Http.Error
    }


type Model
    = LoadingLevels LoadingLevelsModel
    | LoadingDrafts LoadingDraftsModel
    | Loaded LoadedModel
    | Error ErrorModel


init : Session -> ( Model, Cmd Msg )
init session =
    ( LoadingLevels
        { session = session
        }
    , Api.getLevels LoadedLevels
    )


getSession : Model -> Session
getSession model =
    case model of
        LoadingLevels { session } ->
            session

        LoadingDrafts { session } ->
            session

        Loaded { session } ->
            session

        Error { session } ->
            session



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            case model of
                LoadingLevels loadingLevels ->
                    viewLoadingLevels loadingLevels

                LoadingDrafts loadingDrafts ->
                    viewLoadingDrafts loadingDrafts

                Error error ->
                    viewError error

                Loaded loaded ->
                    viewSuccess loaded
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


viewLoadingLevels : LoadingLevelsModel -> Element Msg
viewLoadingLevels model =
    text "Loading levels"


viewLoadingDrafts : LoadingDraftsModel -> Element Msg
viewLoadingDrafts model =
    text "Loading drafts"


viewError : ErrorModel -> Element Msg
viewError { error } =
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


viewSuccess : LoadedModel -> Element Msg
viewSuccess { session, levels, selectedLevel } =
    let
        levelsView =
            viewLevels selectedLevel (Dict.values levels)

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
                Nothing
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
    | LoadedDrafts (Result Http.Error (List Draft))
    | GotLocalStorageResponse ( LocalStorage.Key, LocalStorage.Value )
    | OpenDraftClicked DraftId
    | GeneratedDraft Draft


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            getSession model
    in
    case ( msg, model ) of
        ( SelectLevel selectedLevel, Loaded loadedModel ) ->
            let
                cmd =
                    if List.isEmpty selectedLevel.drafts then
                        Random.generate GeneratedDraft (Draft.generator selectedLevel.level)

                    else
                        Cmd.none
            in
            ( Loaded
                { loadedModel
                    | selectedLevel = Just selectedLevel
                }
            , Cmd.none
            )

        ( OpenDraftClicked draftId, Loaded loadedModel ) ->
            ( model
            , Route.pushUrl loadedModel.session.key (Route.EditDraft draftId)
            )

        ( LoadedLevels result, LoadingLevels _ ) ->
            case result of
                Ok levels ->
                    let
                        levelIds =
                            levels
                                |> List.map .id

                        cmd =
                            case Session.getToken session of
                                Just token ->
                                    Api.getDrafts token levelIds LoadedDrafts

                                Nothing ->
                                    Draft.getDraftsFromLocalStorage "drafts" levelIds
                    in
                    ( LoadingDrafts
                        { session = session
                        , levels = List.sortBy .index levels
                        }
                    , cmd
                    )

                Err error ->
                    ( Error
                        { session = session
                        , error = error
                        }
                    , Cmd.none
                    )

        ( LoadedDrafts drafts, LoadingDrafts loadingDraftsModel ) ->
            ( model, Cmd.none )

        ( GotLocalStorageResponse ( "drafts", value ), LoadingDrafts loadingDraftsModel ) ->
            case Decode.decodeString (Decode.list Draft.decoder) value of
                Ok drafts ->
                    let
                        toLevelProgress level =
                            let
                                levelDrafts =
                                    drafts
                                        |> List.filter (\draft -> draft.levelId == level.id)
                            in
                            { level = level
                            , drafts = levelDrafts
                            }

                        levelProgresses =
                            loadingDraftsModel.levels
                                |> List.map toLevelProgress
                                |> List.map (\progress -> ( progress.level.id, progress ))
                                |> Dict.fromList
                    in
                    ( Loaded
                        { session = session
                        , levels = levelProgresses
                        , selectedLevel = Nothing
                        }
                    , Cmd.none
                    )

                Err error ->
                    ( Error
                        { session = session
                        , error = Http.BadBody (Decode.errorToString error)
                        }
                    , Cmd.none
                    )

        ( GeneratedDraft draft, Loaded loadedModel ) ->
            let
                levels =
                    case Dict.get draft.levelId loadedModel.levels of
                        Just levelProgress ->
                            Dict.insert draft.levelId { levelProgress | drafts = draft :: levelProgress.drafts } loadedModel.levels

                        Nothing ->
                            loadedModel.levels
            in
            ( Loaded { loadedModel | levels = levels }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        LoadingDrafts _ ->
            LocalStorage.storageGetItemResponse GotLocalStorageResponse

        _ ->
            Sub.none
