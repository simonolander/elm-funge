module Page.Campaign exposing
    ( Model
    , Msg(..)
    , init
    , load
    , subscriptions
    , update
    , view
    )

import ApplicationName exposing (applicationName)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Cache as Cache
import Data.Campaign exposing (Campaign)
import Data.CampaignId exposing (CampaignId)
import Data.Draft as Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId exposing (DraftId)
import Data.GetError as GetError exposing (GetError)
import Data.HighScore as HighScore exposing (HighScore)
import Data.History as History
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.RemoteCache as RemoteCache
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.SolutionBook as SolutionBook
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Extra.Cmd
import Extra.RemoteData
import Html
import Html.Attributes
import Json.Decode as Decode
import List.Extra
import Loaders
import Maybe.Extra
import Random
import RemoteData exposing (RemoteData(..))
import Route exposing (Route)
import SessionUpdate exposing (SessionMsg(..))
import Set
import String.Extra
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
    ( model, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadCampaign model =
            Loaders.loadCampaignByCampaignId model.campaignId model.session
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

        loadLevels model =
            Loaders.loadLevelsByCampaignId model.campaignId model.session
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

        loadSolutions model =
            Loaders.loadSolutionsByCampaignId model.campaignId model.session
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

        loadDraftsBySelectedLevelId model =
            case model.selectedLevelId of
                Just levelId ->
                    Loaders.loadDraftsByLevelId levelId model.session
                        |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

                Nothing ->
                    ( model, Cmd.none )

        loadSelectedLevelHighScore model =
            case model.selectedLevelId of
                Just levelId ->
                    Loaders.loadHighScoreByLevelId levelId model.session
                        |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

                Nothing ->
                    ( model, Cmd.none )
    in
    Extra.Cmd.fold
        [ loadCampaign
        , loadLevels
        , loadSolutions
        , loadDraftsBySelectedLevelId
        , loadSelectedLevelHighScore
        ]


withSession : Session -> Model -> Model
withSession session model =
    { model | session = session }



-- UPDATE


type InternalMsg
    = SelectLevel LevelId
    | ClickedOpenDraft DraftId
    | ClickedGenerateDraft
    | GeneratedDraft Draft


type Msg
    = InternalMsg InternalMsg
    | SessionMsg SessionMsg


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        generateDraft levelId =
            Random.generate (InternalMsg << GeneratedDraft) (Draft.generator levelId)
    in
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
                        |> RemoteCache.withLocalValue draft.id (Just draft)
                        |> RemoteCache.withExpectedValue draft.id Nothing
                        |> RemoteCache.withActualValue draft.id Nothing

                draftBook =
                    Cache.get draft.levelId model.session.draftBooks
                        |> RemoteData.toMaybe
                        |> Maybe.withDefault (DraftBook.empty draft.levelId)
                        |> DraftBook.withDraftId draft.id

                draftBookCache =
                    model.session.draftBooks
                        |> Cache.withValue draft.levelId draftBook

                newModel =
                    model.session
                        |> Session.withDraftCache draftCache
                        |> Session.withDraftBookCache draftBookCache
                        |> flip withSession model

                saveDraftToServerCmd =
                    case Session.getAccessToken model.session of
                        Just accessToken ->
                            Just (Draft.saveToServer (SessionMsg << GotSaveDraftResponse draft) accessToken draft)

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
                            View.ErrorScreen.view (GetError.toString error)

                        Success campaign ->
                            viewCampaign campaign model
    in
    { title = String.concat [ "Campaign", " - ", applicationName ]
    , body =
        content
            |> layout
                [ Background.color (rgb 0 0 0)
                , width fill
                , height fill
                , Font.family
                    [ Font.monospace
                    ]
                , Font.color (rgb 1 1 1)
                ]
            |> Html.map InternalMsg
            |> List.singleton
    }


viewError : String -> Element InternalMsg
viewError error =
    View.ErrorScreen.view error


viewCampaign : Campaign -> Model -> Element InternalMsg
viewCampaign campaign model =
    let
        viewTemporarySidebar elements =
            [ el
                [ centerX
                , Font.size 32
                ]
                (text (String.Extra.toSentenceCase model.campaignId))
            , paragraph
                [ width fill
                , Font.center
                ]
                elements
            ]

        numberOfLevels =
            List.length campaign.levelIds

        solutionBookRemoteData =
            List.map (flip Cache.get model.session.solutionBooks) campaign.levelIds

        numberOfSolvedLevels =
            List.filterMap RemoteData.toMaybe solutionBookRemoteData
                |> List.Extra.count (not << Set.isEmpty << .solutionIds)

        allSolutionsLoaded =
            List.map RemoteData.toMaybe solutionBookRemoteData
                |> List.all Maybe.Extra.isJust

        sidebar =
            case
                model.selectedLevelId
                    |> Maybe.Extra.filter (flip List.member campaign.levelIds)
                    |> Maybe.map (flip Session.getLevel model.session)
            of
                Just (Success level) ->
                    viewSidebar level model

                Just NotAsked ->
                    viewTemporarySidebar [ text "Not asked :/" ]

                Just Loading ->
                    viewTemporarySidebar [ text "Loading level..." ]

                Just (Failure error) ->
                    viewTemporarySidebar [ text (GetError.toString error) ]

                Nothing ->
                    viewTemporarySidebar
                        [ String.concat
                            [ if allSolutionsLoaded then
                                ""

                              else
                                "at least "
                            , String.fromInt numberOfSolvedLevels
                            , "/"
                            , String.fromInt numberOfLevels
                            , " solved"
                            ]
                            |> text
                        ]

        mainContent =
            viewLevels campaign model
    in
    View.SingleSidebar.view sidebar mainContent model.session


viewLevels : Campaign -> Model -> Element InternalMsg
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
                    View.Box.simpleError (GetError.toString error)

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


viewSidebar : Level -> Model -> List (Element InternalMsg)
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

        highScoreView =
            if Maybe.Extra.isJust (Session.getAccessToken model.session) then
                let
                    highScore =
                        Cache.get level.id model.session.highScores

                    solutions =
                        Cache.get level.id model.session.solutionBooks
                            |> RemoteData.map (.solutionIds >> Set.toList)
                            |> RemoteData.withDefault []
                            |> List.filterMap (flip Cache.get model.session.solutions.local >> RemoteData.toMaybe)
                            |> Maybe.Extra.values
                in
                View.HighScore.view solutions highScore

            else
                View.Box.simpleNonInteractive "Sign in to enable high scores"

        draftsView =
            viewDrafts level model.session
    in
    [ levelNameView
    , solvedStatusView
    , descriptionView
    , highScoreView
    , draftsView
    ]


viewDrafts : Level -> Session -> Element InternalMsg
viewDrafts level session =
    case Session.getDraftBook level.id session of
        NotAsked ->
            View.Box.simpleLoading "Not asked"

        Loading ->
            View.Box.simpleLoading "Loading drafts"

        Failure error ->
            View.Box.simpleError (GetError.toString error)

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
                            View.Box.simpleError (Decode.errorToString error)

                        Success Nothing ->
                            View.Box.simpleError "Not found"

                        Success (Just draft) ->
                            let
                                maybeSolution =
                                    session.solutionBooks
                                        |> Cache.get level.id
                                        |> RemoteData.map .solutionIds
                                        |> RemoteData.map Set.toList
                                        |> RemoteData.withDefault []
                                        |> List.map (flip Cache.get session.solutions.local)
                                        |> List.filterMap RemoteData.toMaybe
                                        |> Maybe.Extra.values
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
                                    , maybeSolution
                                        |> Maybe.map
                                            (\solution ->
                                                row
                                                    [ width fill
                                                    , spaceEvenly
                                                    ]
                                                    [ text "Steps: "
                                                    , text <| String.fromInt solution.score.numberOfSteps
                                                    ]
                                            )
                                        |> Maybe.withDefault none
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
