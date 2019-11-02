module Page.Campaign.View exposing (view)

import ApplicationName exposing (applicationName)
import Browser exposing (Document)
import Data.GetError as GetError
import Data.Level exposing (Level)
import Data.Session as Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Page.Campaign.Model exposing (Model)
import Page.Campaign.Msg exposing (Msg)
import RemoteData exposing (RemoteData(..))
import String.Extra
import View.Constant exposing (color, size)
import View.ErrorScreen
import View.LoadingScreen


view : Session -> Model -> Document Msg
view session model =
    let
        content =
            case Session.getLevelsByCampaignId model.campaignId session of
                NotAsked ->
                    View.LoadingScreen.view "Not asked for campaign"

                Loading ->
                    View.LoadingScreen.view "Loading campaign"

                Failure error ->
                    View.ErrorScreen.view (GetError.toString error)

                Success levels ->
                    viewCampaign levels model
    in
    { title = "Campaign"
    , body =
        content
            |> layout
                [ color.background.black
                , width fill
                , height fill
                , Font.family
                    [ Font.monospace
                    ]
                , color.font.default
                ]
            |> List.singleton
    }


viewCampaign : List Level -> Session -> Model -> Element Msg
viewCampaign levels session model =
    let
        viewTemporarySidebar elements =
            [ el
                [ centerX
                , size.font.sidebar.title
                ]
                (text (String.Extra.toSentenceCase model.campaignId))
            , paragraph
                [ width fill
                , Font.center
                ]
                elements
            ]

        numberOfLevels =
            List.length levels

        solutionBookRemoteData =
            List.map (flip Cache.get session.solutionBooks) campaign.levelIds

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
                    |> Maybe.map (flip Session.getLevel session)
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
    View.SingleSidebar.view
        { sidebar = sidebar
        , main = mainContent
        , session = session
        , modal = Nothing
        }


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
                        |> flip Session.getSolutionBook session
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
        |> List.map (flip Session.getLevel session)
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

        solutionsAreLoading =
            Cache.get level.id session.solutionBooks
                |> RemoteData.isLoading

        levelSolved =
            Cache.get level.id session.solutionBooks
                |> RemoteData.toMaybe
                |> Maybe.map (.solutionIds >> Set.isEmpty >> not)
                |> Maybe.withDefault False

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
                        Session.getSolutionBook level.id session
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
            if Maybe.Extra.isNothing (Session.getAccessToken session) then
                View.Box.simpleNonInteractive "Sign in to enable high scores"

            else if solutionsAreLoading then
                View.Box.simpleNonInteractive "Loading solutions"

            else if not levelSolved then
                View.Box.simpleNonInteractive "High scores hidden"

            else
                let
                    highScore =
                        Cache.get level.id session.highScores

                    solutions =
                        Cache.get level.id session.solutionBooks
                            |> RemoteData.map (.solutionIds >> Set.toList)
                            |> RemoteData.withDefault []
                            |> List.filterMap (flip Cache.get session.solutions.local >> RemoteData.toMaybe)
                            |> Maybe.Extra.values
                in
                View.HighScore.view solutions highScore

        draftsView =
            viewDrafts level session
    in
    [ levelNameView
    , solvedStatusView
    , descriptionView
    , highScoreView
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
