module Page.Levels exposing (Model, Msg, getSession, init, localStorageResponseUpdate, subscriptions, update, view)

import Api.GCP as GCP
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Campaign as Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft as Draft exposing (Draft)
import Data.DraftId as DraftId exposing (DraftId)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Session as Session exposing (Session)
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html
import Http
import Json.Encode as Encode
import Maybe.Extra
import Ports.LocalStorage as LocalStorage exposing (Key)
import Random
import Result exposing (Result)
import Route exposing (Route)
import View.ErrorScreen
import View.LevelButton
import View.LoadingScreen
import View.SingleSidebar
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    , campaignId : CampaignId
    , selectedLevelId : Maybe LevelId
    , error : Maybe Http.Error
    }


init : CampaignId -> Maybe LevelId -> Session -> ( Model, Cmd Msg )
init campaignId selectedLevelId session =
    let
        model =
            { session = session
            , campaignId = campaignId
            , selectedLevelId = selectedLevelId
            , error = Nothing
            }

        cmd =
            case Dict.get campaignId session.campaigns of
                Nothing ->
                    loadCampaign campaignId session

                Just campaign ->
                    loadLevels campaign session
    in
    ( model, cmd )


loadCampaign : CampaignId -> Session -> Cmd Msg
loadCampaign campaignId session =
    Campaign.loadFromLocalStorage campaignId


loadLevels : Campaign -> Session -> Cmd Msg
loadLevels campaign session =
    let
        loadLevelsCmd =
            campaign.levelIds
                |> List.filter (not << flip Dict.member session.levels)
                |> List.map Level.loadFromLocalStorage
                |> Cmd.batch

        loadDraftsCmd =
            campaign.levelIds
                |> List.map (flip Dict.get session.levels)
                |> Maybe.Extra.values
                |> List.map .id
                |> List.map Draft.loadDraftIdsFromLocalStorage
                |> Cmd.batch

        cmd =
            Cmd.batch
                [ loadLevelsCmd
                , loadDraftsCmd
                ]
    in
    cmd


getSession : Model -> Session
getSession model =
    model.session


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }



-- UPDATE


type Msg
    = SelectLevel LevelId
    | LoadedLevels (Result Http.Error (List Level))
    | LoadedDrafts (Result Http.Error (List Draft))
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
                    Dict.get selectedLevelId model.session.levels

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
                    Route.replaceUrl session.key (Route.Campaign model.campaignId (Just selectedLevelId))

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
                                    GCP.getDrafts token LoadedDrafts

                                Nothing ->
                                    levelIds
                                        |> List.map Level.loadFromLocalStorage
                                        |> Cmd.batch
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

        GeneratedDraft draft ->
            let
                newSession =
                    session.drafts
                        |> Dict.values
                        |> (::) draft
                        |> flip Session.withDrafts session
            in
            ( { model | session = newSession }, Draft.saveToLocalStorage draft )


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate ( key, value ) model =
    let
        session =
            model.session

        onCampaign result =
            case result of
                Ok (Just campaign) ->
                    ( Session.withCampaign campaign session
                        |> setSession model
                    , loadLevels campaign session
                    )

                Ok Nothing ->
                    ( model, Cmd.none )

                Err error ->
                    ( model, Cmd.none )

        onLevel result =
            case result of
                Ok (Just level) ->
                    ( Session.withLevel level session
                        |> setSession model
                    , Draft.loadDraftIdsFromLocalStorage level.id
                    )

                Ok Nothing ->
                    ( model, Cmd.none )

                Err error ->
                    ( model, Cmd.none )

        onDraftIds result =
            case result of
                Ok draftIds ->
                    ( model
                    , draftIds
                        |> List.filter (not << flip Dict.member session.drafts)
                        |> List.map Draft.loadFromLocalStorage
                        |> Cmd.batch
                    )

                Err error ->
                    ( model, Cmd.none )

        onDraft result =
            case result of
                Ok (Just draft) ->
                    ( Session.withDraft draft session
                        |> setSession model
                    , Cmd.none
                    )

                Ok Nothing ->
                    ( model, Cmd.none )

                Err error ->
                    ( model, Cmd.none )
    in
    ( key, value )
        |> LocalStorage.oneOf
            [ Draft.localStorageResponse onDraft
            , Draft.localStorageDraftIdsResponse onDraftIds
            , Level.localStorageResponse onLevel
            , Campaign.localStorageResponse onCampaign
            ]
        |> Maybe.withDefault ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions =
    always Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        session =
            model.session

        content =
            case model.error of
                Just error ->
                    viewError error

                Nothing ->
                    case Dict.get model.campaignId session.campaigns of
                        Just campaign ->
                            viewCampaign campaign model

                        Nothing ->
                            View.LoadingScreen.view "Loading campaign"
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
    let
        errorMessage =
            case error of
                Http.BadUrl string ->
                    "Bad url: " ++ string

                Http.Timeout ->
                    "The request timed out"

                Http.NetworkError ->
                    "Network error"

                Http.BadStatus int ->
                    "Bad status: " ++ String.fromInt int

                Http.BadBody string ->
                    string
    in
    View.ErrorScreen.view errorMessage


viewCampaign : Campaign -> Model -> Element Msg
viewCampaign campaign model =
    let
        selectedLevel =
            model.selectedLevelId
                |> Maybe.Extra.filter (flip List.member campaign.levelIds)
                |> Maybe.andThen (flip Dict.get model.session.levels)

        sidebar =
            case selectedLevel of
                Just level ->
                    viewSidebar level model

                Nothing ->
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

        mainContent =
            viewLevels campaign model
    in
    View.SingleSidebar.view sidebar mainContent model.session


viewLevels : Campaign -> Model -> Element Msg
viewLevels campaign model =
    let
        viewLevel level =
            let
                selected =
                    model.selectedLevelId
                        |> Maybe.map ((==) level.id)
                        |> Maybe.withDefault False

                solved =
                    model.session.drafts
                        |> Dict.values
                        |> List.filter (.levelId >> (==) level.id)
                        |> List.any (.maybeScore >> Maybe.Extra.isJust)

                onPress =
                    Just (SelectLevel level.id)

                default =
                    View.LevelButton.default

                parameters =
                    { default
                        | selected = selected
                        , marked = solved
                        , onPress = onPress
                    }
            in
            View.LevelButton.view
                parameters
                level
    in
    campaign.levelIds
        |> List.map (flip Dict.get model.session.levels)
        |> Maybe.Extra.values
        |> List.sortBy .index
        |> List.map viewLevel
        |> wrappedRow
            [ spacing 20
            ]
        |> el []


viewSidebar : Level -> Model -> List (Element Msg)
viewSidebar level model =
    let
        levelNameView =
            ViewComponents.viewTitle []
                level.name

        descriptionView =
            ViewComponents.descriptionTextbox
                []
                level.description

        drafts =
            Dict.values model.session.drafts
                |> List.filter (.levelId >> (==) level.id)

        solved =
            drafts
                |> List.any (.maybeScore >> Maybe.Extra.isJust)

        solvedStatusView =
            row
                [ centerX ]
                [ el
                    [ width fill
                    ]
                    (if solved then
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
            drafts
                |> List.indexedMap viewDraft
                |> column
                    [ width fill
                    , spacing 20
                    ]
    in
    [ levelNameView
    , solvedStatusView
    , descriptionView
    , draftsView
    ]
