module Page.Levels exposing (Model, Msg, getSession, init, subscriptions, update, view)

import Api
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Draft as Draft exposing (Draft)
import Data.DraftId as DraftId exposing (DraftId)
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
import Route exposing (Route)
import View.LoadingScreen
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    , selectedLevelId : Maybe LevelId
    , error : Maybe Http.Error
    }


init : Maybe LevelId -> Session -> ( Model, Cmd Msg )
init selectedLevelId session =
    let
        model =
            { session = session
            , selectedLevelId = selectedLevelId
            , error = Nothing
            }

        cmd =
            case session.levels of
                Just levelDict ->
                    case session.drafts of
                        Just _ ->
                            Cmd.none

                        Nothing ->
                            levelDict
                                |> Dict.values
                                |> List.map .id
                                |> Draft.getDraftsFromLocalStorage "drafts"

                Nothing ->
                    Api.getLevels LoadedLevels
    in
    ( model, cmd )


getSession : Model -> Session
getSession model =
    model.session



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            case model.error of
                Just error ->
                    viewError error

                Nothing ->
                    case model.session.levels of
                        Just levelDict ->
                            case model.session.drafts of
                                Just draftDict ->
                                    let
                                        levelProgresses =
                                            levelDict
                                                |> Dict.values
                                                |> List.map
                                                    (\level ->
                                                        { level = level
                                                        , drafts =
                                                            draftDict
                                                                |> Dict.values
                                                                |> List.filter (\draft -> draft.levelId == level.id)
                                                        }
                                                    )
                                                |> List.map (\levelProgress -> ( levelProgress.level.id, levelProgress ))
                                                |> Dict.fromList
                                    in
                                    viewSuccess model.session levelProgresses model.selectedLevelId

                                Nothing ->
                                    View.LoadingScreen.view "Loading drafts"

                        Nothing ->
                            View.LoadingScreen.view "Loading levels"
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


viewError : Http.Error -> Element Msg
viewError error =
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


viewSuccess : Session -> Dict LevelId LevelProgress -> Maybe LevelId -> Element Msg
viewSuccess session levels selectedLevelId =
    let
        levelsView =
            viewLevels selectedLevelId (Dict.values levels)

        sidebarView =
            selectedLevelId
                |> Maybe.andThen (flip Dict.get levels)
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


viewLevels : Maybe LevelId -> List LevelProgress -> Element Msg
viewLevels maybeSelectedLevelId levelProgresses =
    let
        viewLevel levelProgress =
            let
                selected =
                    maybeSelectedLevelId
                        |> Maybe.map ((==) levelProgress.level.id)
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
                    Just (SelectLevel levelProgress.level.id)
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
        |> List.sortBy (.level >> .index)
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
        level =
            levelProgress.level

        levelNameView =
            ViewComponents.viewTitle []
                level.name

        descriptionView =
            ViewComponents.descriptionTextbox
                []
                level.description

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

        viewDraft index draft =
            let
                attrs =
                    [ width fill
                    , padding 10
                    , spacing 15
                    , Border.width 3
                    , Border.color (rgb 1 1 1)
                    , centerX
                    , mouseOver
                        [ Background.color (rgb 0.5 0.5 0.5)
                        ]
                    ]

                draftName =
                    "Draft " ++ String.fromInt (index + 1)

                label =
                    [ draftName
                        |> text
                        |> el [ centerX, Font.size 24 ]
                    , el
                        [ centerX
                        , Font.color (rgb 0.2 0.2 0.2)
                        ]
                        (text draft.id)
                    , row
                        [ width fill
                        , spaceEvenly
                        ]
                        [ text "Instructions: "
                        , Draft.getInstructionCount level.initialBoard draft
                            |> String.fromInt
                            |> text
                        ]
                    , row
                        [ width fill
                        , spaceEvenly
                        ]
                        [ text "Steps: "
                        , draft.maybeScore
                            |> Maybe.map .numberOfSteps
                            |> Maybe.map String.fromInt
                            |> Maybe.withDefault "N/A"
                            |> text
                        ]
                    ]
                        |> column
                            attrs
            in
            Route.link
                [ width fill ]
                label
                (Route.EditDraft draft.id)

        draftsView =
            levelProgress.drafts
                |> List.indexedMap viewDraft
                |> column
                    [ width fill
                    , spacing 20
                    ]
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
        , draftsView
        ]



-- UPDATE


type Msg
    = SelectLevel LevelId
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
    case msg of
        SelectLevel selectedLevelId ->
            let
                maybeSelectedLevel =
                    model.session.levels
                        |> Maybe.andThen (Dict.get selectedLevelId)

                generateDraftCmd =
                    case maybeSelectedLevel of
                        Just selectedLevel ->
                            if List.isEmpty (Session.getLevelDrafts selectedLevelId session) then
                                Random.generate
                                    GeneratedDraft
                                    (Draft.generator selectedLevel)

                            else
                                Cmd.none

                        Nothing ->
                            Cmd.none

                changeUrlCmd =
                    Route.replaceUrl session.key (Route.Levels (Just selectedLevelId))

                cmd =
                    Cmd.batch
                        [ generateDraftCmd
                        , changeUrlCmd
                        ]
            in
            ( { model
                | selectedLevelId = Just selectedLevelId
              }
            , cmd
            )

        OpenDraftClicked draftId ->
            ( model
            , Route.pushUrl model.session.key (Route.EditDraft draftId)
            )

        LoadedLevels result ->
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
                    ( { model
                        | session = Session.withLevels levels session
                      }
                    , cmd
                    )

                Err error ->
                    ( { model
                        | error = Just error
                      }
                    , Cmd.none
                    )

        LoadedDrafts result ->
            case result of
                Ok drafts ->
                    ( { model
                        | session = Session.withDrafts drafts session
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | error = Just error
                      }
                    , Cmd.none
                    )

        GotLocalStorageResponse ( "drafts", value ) ->
            case Decode.decodeValue (Decode.list Draft.decoder) value of
                Ok drafts ->
                    ( { model
                        | session = Session.withDrafts drafts session
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { model
                        | error =
                            Decode.errorToString error
                                |> Http.BadBody
                                |> Just
                      }
                    , Cmd.none
                    )

        GeneratedDraft draft ->
            let
                newSession =
                    session.drafts
                        |> Maybe.map Dict.values
                        |> Maybe.map ((::) draft)
                        |> Maybe.map (flip Session.withDrafts session)
                        |> Maybe.withDefault session
            in
            ( { model | session = newSession }, Draft.saveToLocalStorage draft )

        _ ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    LocalStorage.storageGetItemResponse GotLocalStorageResponse
