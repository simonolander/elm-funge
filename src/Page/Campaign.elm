module Page.Campaign exposing (Model, Msg, getSession, init, localStorageResponseUpdate, subscriptions, update, view)

import Api.GCP as GCP
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Cache as Cache
import Data.Campaign as Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft as Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId as DraftId exposing (DraftId)
import Data.HighScore as HighScore exposing (HighScore)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Extra.RemoteData
import Extra.String exposing (fromHttpError)
import Html.Attributes
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
import View.Box
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
    in
    load model


load : Model -> ( Model, Cmd Msg )
load model =
    case Session.getCampaign model.campaignId model.session of
        Success campaign ->
            let
                ( loadingLevelsModel, loadLevelsCmd ) =
                    let
                        notAskedLevelIds =
                            campaign.levelIds
                                |> List.filter (flip Cache.isNotAsked model.session.levels)
                    in
                    ( notAskedLevelIds
                        |> List.foldl Session.levelLoading model.session
                        |> setSession model
                    , notAskedLevelIds
                        |> List.map Level.loadFromLocalStorage
                        |> Cmd.batch
                    )

                ( selectedLevelModel, loadSelectedLevelCmd ) =
                    case model.selectedLevelId of
                        Just levelId ->
                            let
                                ( loadingDraftBookModel, loadDraftBookCmd ) =
                                    case Session.getDraftBook levelId loadingLevelsModel.session of
                                        NotAsked ->
                                            ( loadingLevelsModel.session
                                                |> Session.draftBookLoading levelId
                                                |> setSession loadingLevelsModel
                                            , DraftBook.loadFromLocalStorage levelId
                                            )

                                        Success draftBook ->
                                            let
                                                notAskedDraftIds =
                                                    draftBook.draftIds
                                                        |> Set.toList
                                                        |> List.filter (flip Cache.isNotAsked loadingLevelsModel.session.drafts)
                                            in
                                            ( notAskedDraftIds
                                                |> List.foldl Session.draftLoading loadingLevelsModel.session
                                                |> setSession loadingLevelsModel
                                            , notAskedDraftIds
                                                |> List.map Draft.loadFromLocalStorage
                                                |> Cmd.batch
                                            )

                                        _ ->
                                            ( loadingLevelsModel, Cmd.none )

                                ( loadingHighScoreModel, loadHighScoreCmd ) =
                                    case Session.getHighScore levelId loadingDraftBookModel.session of
                                        NotAsked ->
                                            case Session.getToken loadingDraftBookModel.session of
                                                Just _ ->
                                                    ( loadingDraftBookModel.session
                                                        |> Session.loadingHighScore levelId
                                                        |> setSession loadingDraftBookModel
                                                    , HighScore.loadFromServer levelId LoadedHighScore
                                                    )

                                                Nothing ->
                                                    ( loadingDraftBookModel, Cmd.none )

                                        _ ->
                                            ( loadingDraftBookModel, Cmd.none )
                            in
                            ( loadingHighScoreModel
                            , Cmd.batch
                                [ loadDraftBookCmd
                                , loadHighScoreCmd
                                ]
                            )

                        Nothing ->
                            ( loadingLevelsModel, Cmd.none )
            in
            ( selectedLevelModel
            , Cmd.batch
                [ loadLevelsCmd
                , loadSelectedLevelCmd
                ]
            )

        NotAsked ->
            ( model.session
                |> Session.campaignLoading model.campaignId
                |> setSession model
            , Campaign.loadFromLocalStorage model.campaignId
            )

        _ ->
            ( model, Cmd.none )


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
            let
                ( newModel, loadCmd ) =
                    load { model | selectedLevelId = Just selectedLevelId }

                changeUrlCmd =
                    Route.replaceUrl session.key (Route.Campaign model.campaignId (Just selectedLevelId))

                cmd =
                    Cmd.batch
                        [ changeUrlCmd
                        , loadCmd
                        ]
            in
            ( newModel, cmd )

        ClickedOpenDraft draftId ->
            ( model
            , Route.pushUrl model.session.key (Route.EditDraft draftId)
            )

        ClickedGenerateDraft ->
            case
                model.selectedLevelId
                    |> Maybe.map (flip Session.getLevel session)
            of
                Just (Success level) ->
                    ( model, generateDraft level )

                _ ->
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
                    Session.withHighScoreResult requestResult session

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
                newModel =
                    Session.withDraft draft session
                        |> setSession model

                cmd =
                    Cmd.batch
                        [ Draft.saveToLocalStorage draft
                        , Route.pushUrl session.key (Route.EditDraft draft.id)
                        ]
            in
            ( newModel, cmd )


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate ( key, value ) model =
    let
        session =
            model.session

        onCampaign result =
            case result of
                Ok (Just campaign) ->
                    Session.withCampaign campaign session
                        |> setSession model
                        |> load

                -- TODO
                Ok Nothing ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model
                        | error = Just (Json.Decode.errorToString error)
                      }
                    , Ports.Console.errorString (Json.Decode.errorToString error)
                    )

        onLevel result =
            case result of
                Ok (Just level) ->
                    Session.withLevel level session
                        |> setSession model
                        |> load

                -- TODO
                Ok Nothing ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model
                        | error = Just (Json.Decode.errorToString error)
                      }
                    , Ports.Console.errorString (Json.Decode.errorToString error)
                    )

        onDraftBook result =
            case result of
                Ok draftBook ->
                    Session.withDraftBook draftBook session
                        |> setSession model
                        |> load

                Err error ->
                    ( { model
                        | error = Just (Json.Decode.errorToString error)
                      }
                    , Ports.Console.errorString (Json.Decode.errorToString error)
                    )

        onDraft result =
            case result of
                Ok (Just draft) ->
                    Session.withDraft draft session
                        |> setSession model
                        |> load

                Ok Nothing ->
                    ( model, Cmd.none )

                Err error ->
                    ( { model
                        | error = Just (Json.Decode.errorToString error)
                      }
                    , Ports.Console.errorString (Json.Decode.errorToString error)
                    )
    in
    ( key, value )
        |> LocalStorage.oneOf
            [ Campaign.localStorageResponse onCampaign
            , Level.localStorageResponse onLevel
            , DraftBook.localStorageResponse onDraftBook
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
                    case Session.getCampaign model.campaignId session of
                        NotAsked ->
                            View.LoadingScreen.view "Not asked for campaign"

                        Loading ->
                            View.LoadingScreen.view "Loading campaign..."

                        Failure error ->
                            View.ErrorScreen.view (Extra.String.fromHttpError error)

                        Success campaign ->
                            viewCampaign campaign model
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
        viewTemporarySidebar message =
            [ el
                [ centerX
                , Font.size 32
                ]
                (text "EFNG")
            , paragraph
                [ width fill
                , Font.center
                ]
                [ text message ]
            ]

        sidebar =
            case
                model.selectedLevelId
                    |> Maybe.Extra.filter (flip List.member campaign.levelIds)
                    |> Maybe.map (flip Session.getLevel model.session)
            of
                Just (Success level) ->
                    viewSidebar level model

                Just NotAsked ->
                    viewTemporarySidebar "Not asked :/"

                Just Loading ->
                    viewTemporarySidebar "Loading level..."

                Just (Failure error) ->
                    viewTemporarySidebar (Extra.String.fromHttpError error)

                Nothing ->
                    viewTemporarySidebar "Select a level"

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
                    level.id
                        |> flip Session.getDraftBook model.session
                        |> RemoteData.map .draftIds
                        |> RemoteData.map Set.toList
                        |> RemoteData.withDefault []
                        |> List.map (flip Session.getDraft model.session)
                        |> List.map (RemoteData.map .maybeScore)
                        |> List.map (RemoteData.map Maybe.Extra.isJust)
                        |> List.any ((==) (Success True))

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

        viewLevelWebData webData =
            case webData of
                NotAsked ->
                    View.Box.simpleNonInteractive "Not asked :/"

                Loading ->
                    View.Box.simpleNonInteractive "Loading level..."

                Failure error ->
                    View.Box.simpleError (Extra.String.fromHttpError error)

                Success level ->
                    viewLevel level

        sort d1 d2 =
            case ( d1, d2 ) of
                ( Success a, Success b ) ->
                    compare a.index b.index

                ( Success _, _ ) ->
                    LT

                ( _, Success _ ) ->
                    GT

                _ ->
                    EQ
    in
    campaign.levelIds
        |> List.map (flip Session.getLevel model.session)
        |> List.sortWith sort
        |> List.map viewLevelWebData
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

        solvedStatusView =
            let
                solvedStatus =
                    case
                        Session.getDraftBook level.id model.session
                    of
                        Success draftBook ->
                            let
                                drafts =
                                    draftBook.draftIds
                                        |> Set.toList
                                        |> List.map (flip Session.getDraft model.session)

                                anySolved =
                                    drafts
                                        |> Extra.RemoteData.successes
                                        |> List.any (.maybeScore >> Maybe.Extra.isJust)

                                anyLoading =
                                    List.any RemoteData.isLoading drafts
                            in
                            if anySolved then
                                "Solved"

                            else if anyLoading then
                                "Loading drafts..."

                            else
                                "Not solved"

                        _ ->
                            "Loading drafts..."
            in
            paragraph
                [ width fill
                , Font.center
                ]
                [ text solvedStatus
                ]

        highScore =
            if Maybe.Extra.isJust (Session.getToken model.session) then
                Session.getHighScore level.id model.session
                    |> View.HighScore.view

            else
                View.Box.simpleNonInteractive "Sign in to enable high scores"

        draftsView =
            viewDrafts level model.session
    in
    [ levelNameView
    , solvedStatusView
    , descriptionView
    , highScore
    , draftsView
    ]


viewDrafts : Level -> Session -> Element Msg
viewDrafts level session =
    case Session.getDraftBook level.id session of
        NotAsked ->
            View.Box.simpleNonInteractive "Not asked"

        Loading ->
            View.Box.simpleNonInteractive "Loading drafts"

        Failure error ->
            View.Box.simpleError (Extra.String.fromHttpError error)

        Success draftBook ->
            let
                newDraftButton =
                    ViewComponents.textButton
                        []
                        (Just ClickedGenerateDraft)
                        "New draft"

                viewDraft index draftId =
                    case Session.getDraft draftId session of
                        NotAsked ->
                            View.Box.simpleNonInteractive "Not asked"

                        Loading ->
                            View.Box.simpleNonInteractive ("Loading draft " ++ String.fromInt (index + 1))

                        Failure error ->
                            View.Box.simpleError (Extra.String.fromHttpError error)

                        Success draft ->
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
                                    , htmlAttribute
                                        (Html.Attributes.class
                                            (if Maybe.Extra.isJust draft.maybeScore then
                                                "solved"

                                             else
                                                ""
                                            )
                                        )
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
            in
            draftBook.draftIds
                |> Set.toList
                |> List.indexedMap viewDraft
                |> (::) newDraftButton
                |> column
                    [ width fill
                    , spacing 20
                    ]
