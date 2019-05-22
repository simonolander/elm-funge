module Page.Campaign exposing (Model, Msg, getSession, init, localStorageResponseUpdate, subscriptions, update, view)

import Api.GCP as GCP
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Campaign as Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft as Draft exposing (Draft)
import Data.DraftId as DraftId exposing (DraftId)
import Data.HighScore exposing (HighScore)
import Data.Level as Level exposing (Level)
import Data.LevelDrafts as LevelDrafts exposing (LevelDrafts)
import Data.LevelId exposing (LevelId)
import Data.RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Dict exposing (Dict)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Extra.String exposing (fromHttpError)
import Http
import Json.Decode
import Json.Encode as Encode
import Maybe.Extra
import Ports.Console
import Ports.LocalStorage as LocalStorage exposing (Key)
import Random
import RemoteData exposing (RemoteData(..))
import Result exposing (Result)
import Route exposing (Route)
import Set
import View.ErrorScreen
import View.HighScore
import View.LevelButton
import View.LoadingScreen
import View.SingleSidebar
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    , campaignId : CampaignId
    , selectedLevelId : Maybe LevelId
    , error : Maybe String
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
            initCampaignId campaignId session
    in
    ( model, cmd )


initCampaignId : CampaignId -> Session -> Cmd Msg
initCampaignId campaignId session =
    case Dict.get campaignId session.campaigns of
        Nothing ->
            Campaign.loadFromLocalStorage campaignId

        Just campaign ->
            campaign.levelIds
                |> List.map (flip initLevelId session)
                |> Cmd.batch


initLevelId : LevelId -> Session -> Cmd Msg
initLevelId levelId session =
    case Dict.get levelId session.levels of
        Just level ->
            Cmd.none

        Nothing ->
            Level.loadFromLocalStorage levelId


initLevelDrafts : LevelId -> Session -> Cmd Msg
initLevelDrafts levelId session =
    LevelDrafts.loadFromLocalStorage levelId


initDraft : DraftId -> Session -> Cmd Msg
initDraft draftId session =
    case Dict.get draftId session.drafts of
        Just draft ->
            Cmd.none

        Nothing ->
            Draft.loadFromLocalStorage draftId


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
    | LoadedHighScore (RequestResult LevelId HighScore)
    | ClickedOpenDraft DraftId
    | ClickedGenerateDraft
    | GeneratedDraft Draft


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            getSession model

        generateDraft levelId =
            Random.generate GeneratedDraft (Draft.generator levelId)
    in
    case msg of
        SelectLevel selectedLevelId ->
            case Dict.get selectedLevelId session.levels of
                Just selectedLevel ->
                    let
                        loadLevelDraftsCmd =
                            initLevelDrafts selectedLevelId session

                        generateDraftCmd =
                            case Session.getLevelDrafts selectedLevelId session of
                                Success levelDrafts ->
                                    if Set.isEmpty levelDrafts.draftIds then
                                        Random.generate
                                            GeneratedDraft
                                            (Draft.generator selectedLevel)

                                    else
                                        Cmd.none

                                _ ->
                                    Cmd.none

                        changeUrlCmd =
                            Route.replaceUrl session.key (Route.Campaign model.campaignId (Just selectedLevelId))

                        loadHighScoreCmd =
                            GCP.getHighScore selectedLevelId LoadedHighScore

                        cmd =
                            Cmd.batch
                                [ generateDraftCmd
                                , changeUrlCmd
                                , loadHighScoreCmd
                                , loadLevelDraftsCmd
                                ]
                    in
                    ( { model
                        | selectedLevelId = Just selectedLevelId
                      }
                    , cmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        ClickedOpenDraft draftId ->
            ( model
            , Route.pushUrl model.session.key (Route.EditDraft draftId)
            )

        ClickedGenerateDraft ->
            let
                maybeSelectedLevel =
                    model.selectedLevelId
                        |> Maybe.andThen (flip Dict.get session.levels)
            in
            case maybeSelectedLevel of
                Just level ->
                    ( model, generateDraft level )

                Nothing ->
                    ( model, Cmd.none )

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
                        | error = Just (fromHttpError error)
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
                        | error = Just (fromHttpError error)
                      }
                    , Cmd.none
                    )

        LoadedHighScore requestResult ->
            let
                newSession =
                    Session.withHighScore requestResult session

                newModel =
                    setSession model newSession

                cmd =
                    Cmd.none
            in
            ( newModel
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
                    , campaign.levelIds
                        |> List.map (flip initLevelId session)
                        |> Cmd.batch
                    )

                -- TODO
                Ok Nothing ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model | error = Just (Json.Decode.errorToString error) }, Cmd.none )

        onLevel result =
            case result of
                Ok (Just level) ->
                    ( Session.withLevel level session
                        |> setSession model
                    , Cmd.none
                    )

                -- TODO
                Ok Nothing ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model | error = Just (Json.Decode.errorToString error) }, Cmd.none )

        onLevelDrafts result =
            case result of
                Ok (Just levelDrafts) ->
                    ( Session.withLevelDrafts levelDrafts session
                        |> setSession model
                        |> Debug.log "log"
                    , levelDrafts
                        |> .draftIds
                        |> Set.toList
                        |> List.filter (not << flip Dict.member session.drafts)
                        |> List.map Draft.loadFromLocalStorage
                        |> (::) (Ports.Console.log (LevelDrafts.encode levelDrafts))
                        |> Cmd.batch
                    )

                Ok Nothing ->
                    case model.selectedLevelId of
                        Just levelId ->
                            ( Session.withLevelDrafts (LevelDrafts.empty levelId) session
                                |> setSession model
                            , Cmd.none
                            )

                        Nothing ->
                            ( model
                            , Ports.Console.errorString "YIO5XLw3FQVsRyaj"
                            )

                Err error ->
                    ( { model | error = Just (Json.Decode.errorToString error) }, Cmd.none )

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
                    ( { model | error = Just (Json.Decode.errorToString error) }, Cmd.none )
    in
    ( key, value )
        |> LocalStorage.oneOf
            [ Campaign.localStorageResponse onCampaign
            , Level.localStorageResponse onLevel
            , LevelDrafts.localStorageResponse onLevelDrafts
            , Draft.localStorageResponse onDraft
            ]
        |> Maybe.withDefault
            ( model
            , Ports.Console.errorString ("No matching localStorageResponse for key: " ++ key)
            )



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


viewError : String -> Element Msg
viewError error =
    View.ErrorScreen.view error


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

        highScore =
            Session.getHighScore level.id model.session
                |> View.HighScore.view

        newDraftButton =
            ViewComponents.textButton
                []
                (Just ClickedGenerateDraft)
                "New draft"

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
                |> (::) newDraftButton
                |> column
                    [ width fill
                    , spacing 20
                    ]
    in
    [ levelNameView
    , solvedStatusView
    , descriptionView
    , highScore
    , draftsView
    ]
