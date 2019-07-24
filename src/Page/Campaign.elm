module Page.Campaign exposing
    ( Model
    , Msg(..)
    , getSession
    , init
    , load
    , subscriptions
    , update
    , updateSession
    , view
    )

import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Cache as Cache
import Data.Campaign as Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.DetailedHttpError as DetailedHttpError exposing (DetailedHttpError)
import Data.Draft as Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId exposing (DraftId)
import Data.HighScore as HighScore exposing (HighScore)
import Data.History as History
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.SolutionBook as SolutionBook
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Extra.Cmd
import Extra.RemoteData
import Html.Attributes
import Maybe.Extra
import Ports.Console
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
    load ( model, Cmd.none )


load : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
load =
    let
        loadCampaign model =
            case Session.getCampaign model.campaignId model.session of
                NotAsked ->
                    let
                        loadCampaignRemotely =
                            Level.loadFromServerByCampaignId (SessionMsg << GotLoadLevelsByCampaignIdResponse) model.campaignId

                        loadCampaignLocally =
                            Campaign.loadFromLocalStorage model.campaignId
                    in
                    ( model.session
                        |> Session.campaignLoading model.campaignId
                        |> flip withSession model
                    , loadCampaignRemotely
                    )

                _ ->
                    ( model, Cmd.none )

        loadLevels model =
            case
                model.session
                    |> Session.getCampaign model.campaignId
                    |> RemoteData.toMaybe
            of
                Just campaign ->
                    let
                        notAskedLevelIds =
                            campaign.levelIds
                                |> List.filter (flip Cache.isNotAsked model.session.levels)
                    in
                    ( notAskedLevelIds
                        |> List.foldl Session.levelLoading model.session
                        |> flip withSession model
                    , notAskedLevelIds
                        -- TODO Load from server if accessToken?
                        |> List.map Level.loadFromLocalStorage
                        |> Cmd.batch
                    )

                Nothing ->
                    ( model, Cmd.none )

        loadSolutionBooks model =
            case
                model.session
                    |> Session.getCampaign model.campaignId
                    |> RemoteData.toMaybe
            of
                Just campaign ->
                    let
                        notAskedLevelIds =
                            campaign.levelIds
                                |> List.filter (flip Cache.isNotAsked model.session.solutionBooks)

                        loadSolutionBook =
                            case Session.getAccessToken model.session of
                                Just accessToken ->
                                    Solution.loadFromServerByLevelId accessToken (SessionMsg << GotLoadSolutionsByLevelIdResponse)

                                Nothing ->
                                    SolutionBook.loadFromLocalStorage
                    in
                    ( notAskedLevelIds
                        |> List.foldl Session.solutionBookLoading model.session
                        |> flip withSession model
                    , notAskedLevelIds
                        |> List.map loadSolutionBook
                        |> Cmd.batch
                    )

                Nothing ->
                    ( model, Cmd.none )

        loadSolutions model =
            case
                model.session
                    |> Session.getCampaign model.campaignId
                    |> RemoteData.toMaybe
            of
                Just campaign ->
                    let
                        notAskedSolutionIds =
                            campaign.levelIds
                                |> List.map (flip Session.getSolutionBook model.session)
                                |> Extra.RemoteData.successes
                                |> List.map .solutionIds
                                |> List.map Set.toList
                                |> List.concat
                                |> List.filter (flip Cache.isNotAsked model.session.solutions)
                    in
                    ( notAskedSolutionIds
                        |> List.foldl Session.solutionLoading model.session
                        |> flip withSession model
                    , notAskedSolutionIds
                        |> List.map Solution.loadFromLocalStorage
                        |> Cmd.batch
                    )

                Nothing ->
                    ( model, Cmd.none )

        loadSelectedLevelDraftBook model =
            case model.selectedLevelId of
                Just levelId ->
                    case Session.getDraftBook levelId model.session of
                        NotAsked ->
                            ( model.session
                                |> Session.draftBookLoading levelId
                                |> flip withSession model
                            , DraftBook.loadFromLocalStorage levelId
                            )

                        _ ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        loadSelectedLevelDrafts model =
            case
                model.selectedLevelId
                    |> Maybe.map (flip Session.getDraftBook model.session)
                    |> Maybe.andThen RemoteData.toMaybe
            of
                Just draftBook ->
                    let
                        notAskedDraftIds =
                            draftBook.draftIds
                                |> Set.toList
                                |> List.filter (flip Cache.isNotAsked model.session.drafts.local)
                    in
                    ( notAskedDraftIds
                        |> List.foldl RemoteCache.withLocalLoading model.session.drafts
                        |> flip Session.withDraftCache model.session
                        |> flip withSession model
                    , notAskedDraftIds
                        |> List.map Draft.loadFromLocalStorage
                        |> Cmd.batch
                    )

                Nothing ->
                    ( model, Cmd.none )

        loadSelectedLevelHighScore model =
            case model.selectedLevelId of
                Just levelId ->
                    case Session.getHighScore levelId model.session of
                        NotAsked ->
                            case Session.getAccessToken model.session of
                                Just _ ->
                                    ( model.session
                                        |> Session.loadingHighScore levelId
                                        |> flip withSession model
                                    , HighScore.loadFromServer levelId (SessionMsg << GotLoadHighScoreResponse)
                                    )

                                Nothing ->
                                    ( model, Cmd.none )

                        _ ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )
    in
    Extra.Cmd.fold
        [ loadCampaign
        , loadLevels
        , loadSolutionBooks
        , loadSolutions
        , loadSelectedLevelDraftBook
        , loadSelectedLevelDrafts
        , loadSelectedLevelHighScore
        ]


getSession : Model -> Session
getSession model =
    model.session


withSession : Session -> Model -> Model
withSession session model =
    { model | session = session }



-- UPDATE


type Msg
    = SelectLevel LevelId
    | ClickedOpenDraft DraftId
    | ClickedGenerateDraft
    | GeneratedDraft Draft
    | SessionMsg SessionMsg


type SessionMsg
    = GotLoadHighScoreResponse (RequestResult LevelId DetailedHttpError HighScore)
    | GotLoadLevelsByCampaignIdResponse (RequestResult CampaignId DetailedHttpError (List Level))
    | GotLoadSolutionsByLevelIdResponse (RequestResult LevelId DetailedHttpError (List Solution))
    | GotSaveDraftResponse (RequestResult Draft DetailedHttpError ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        generateDraft levelId =
            Random.generate GeneratedDraft (Draft.generator levelId)
    in
    load <|
        case msg of
            SelectLevel selectedLevelId ->
                ( { model
                    | selectedLevelId = Just selectedLevelId
                  }
                , Route.replaceUrl model.session.key (Route.Campaign model.campaignId (Just selectedLevelId))
                )

            ClickedOpenDraft draftId ->
                ( model
                , Route.pushUrl model.session.key (Route.EditDraft draftId)
                )

            ClickedGenerateDraft ->
                case
                    model.selectedLevelId
                        |> Maybe.map (flip Session.getLevel model.session)
                of
                    Just (Success level) ->
                        ( model, generateDraft level )

                    _ ->
                        ( model, Cmd.none )

            GeneratedDraft draft ->
                let
                    draftCache =
                        model.session.drafts
                            |> RemoteCache.withLocalValue draft.id draft

                    draftBook =
                        Cache.get draft.levelId model.session.draftBooks
                            |> RemoteData.toMaybe
                            |> Maybe.withDefault (DraftBook.empty draft.levelId)
                            |> DraftBook.withDraftId draft.id

                    draftBookCache =
                        model.session.draftBooks
                            |> Cache.insert draft.levelId draftBook

                    newModel =
                        model.session
                            |> Session.withDraftCache draftCache
                            |> Session.withDraftBookCache draftBookCache
                            |> flip withSession model

                    saveDraftToServerCmd =
                        case Session.getAccessToken model.session of
                            Just accessToken ->
                                Just (Draft.saveToServer accessToken (SessionMsg << GotSaveDraftResponse) draft)

                            Nothing ->
                                Nothing

                    cmd =
                        [ Just (Draft.saveToLocalStorage draft)
                        , saveDraftToServerCmd
                        , Just (Route.pushUrl model.session.key (Route.EditDraft draft.id))
                        ]
                            |> Maybe.Extra.values
                            |> Cmd.batch
                in
                ( newModel, cmd )

            SessionMsg sessionMsg ->
                updateSession sessionMsg model.session
                    |> Extra.Cmd.mapModel (flip withSession model)


updateSession : SessionMsg -> Session -> ( Session, Cmd Msg )
updateSession msg session =
    case msg of
        GotLoadHighScoreResponse requestResult ->
            ( Session.withHighScoreResult requestResult session
            , Cmd.none
            )

        GotLoadLevelsByCampaignIdResponse requestResult ->
            case requestResult.result of
                Ok levels ->
                    let
                        campaign =
                            { id = requestResult.request
                            , levelIds = List.map .id levels
                            }

                        saveCampaignLocallyCmd =
                            Campaign.saveToLocalStorage campaign

                        saveLevelsLocallyCmd =
                            levels
                                |> List.map Level.saveToLocalStorage
                                |> Cmd.batch

                        cmd =
                            Cmd.batch
                                [ saveCampaignLocallyCmd
                                , saveLevelsLocallyCmd
                                ]
                    in
                    ( session
                        |> Session.withCampaign campaign
                        |> Session.withLevels levels
                    , cmd
                    )

                -- TODO
                Err error ->
                    ( session
                    , Ports.Console.errorString (DetailedHttpError.toString error)
                    )

        GotLoadSolutionsByLevelIdResponse requestResult ->
            case requestResult.result of
                Ok solutions ->
                    let
                        solutionBook =
                            { levelId = requestResult.request
                            , solutionIds =
                                solutions
                                    |> List.map .id
                                    |> Set.fromList
                            }

                        cmd =
                            solutions
                                |> List.map Solution.saveToLocalStorage
                                |> Cmd.batch
                    in
                    ( session
                        |> Session.withSolutionBook solutionBook
                        |> Session.withSolutions solutions
                    , cmd
                    )

                -- TODO
                Err error ->
                    ( session
                    , Ports.Console.errorString (DetailedHttpError.toString error)
                    )

        GotSaveDraftResponse { request, result } ->
            case result of
                Ok () ->
                    Debug.todo "fb421adc-f203-443f-b134-c4e5843943e5"

                Err error ->
                    Debug.todo "5d68bcf1-48b9-45c5-9e4b-905f06ec6cb8"



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
                            View.LoadingScreen.view "Loading campaign"

                        Failure error ->
                            View.ErrorScreen.view (DetailedHttpError.toString error)

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
                    viewTemporarySidebar (DetailedHttpError.toString error)

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
                        |> flip Session.getSolutionBook model.session
                        |> RemoteData.map .solutionIds
                        |> RemoteData.map Set.isEmpty
                        |> RemoteData.withDefault True
                        |> not

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
                    View.Box.simpleLoading "Not asked :/"

                Loading ->
                    View.Box.simpleLoading "Loading level..."

                Failure error ->
                    View.Box.simpleError (DetailedHttpError.toString error)

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
                loadingText =
                    "Loading solutions..."

                solvedText =
                    "Solved"

                notSolvedText =
                    "Not solved"

                solvedStatus =
                    case
                        Session.getSolutionBook level.id model.session
                    of
                        Success solutionBook ->
                            if Set.isEmpty solutionBook.solutionIds then
                                notSolvedText

                            else
                                solvedText

                        _ ->
                            loadingText
            in
            paragraph
                [ width fill
                , Font.center
                ]
                [ text solvedStatus
                ]

        highScore =
            if Maybe.Extra.isJust (Session.getAccessToken model.session) then
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
            View.Box.simpleLoading "Not asked"

        Loading ->
            View.Box.simpleLoading "Loading drafts"

        Failure error ->
            View.Box.simpleError (DetailedHttpError.toString error)

        Success draftBook ->
            let
                newDraftButton =
                    ViewComponents.textButton
                        []
                        (Just ClickedGenerateDraft)
                        "New draft"

                viewDraft index draftId =
                    case Cache.get draftId session.drafts.local of
                        NotAsked ->
                            View.Box.simpleLoading "Not asked"

                        Loading ->
                            View.Box.simpleLoading ("Loading draft " ++ String.fromInt (index + 1))

                        Failure error ->
                            View.Box.simpleError (DetailedHttpError.toString error)

                        Success draft ->
                            let
                                maybeSolution =
                                    Session.getSolutionBook level.id session
                                        |> RemoteData.map .solutionIds
                                        |> RemoteData.map Set.toList
                                        |> RemoteData.withDefault []
                                        |> List.map (flip Session.getSolution session)
                                        |> Extra.RemoteData.successes
                                        |> List.filter (.board >> (==) (History.current draft.boardHistory))
                                        |> List.head

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
                                            (if Maybe.Extra.isJust maybeSolution then
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
                                        , maybeSolution
                                            |> Maybe.map .score
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
