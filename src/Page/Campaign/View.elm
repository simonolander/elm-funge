module Page.Campaign.View exposing (view)

import Data.Draft as Draft
import Data.GetError as GetError
import Data.History as History
import Data.Level exposing (Level)
import Data.Session exposing (Session)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Element exposing (..)
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import List.Extra
import Maybe.Extra
import Page.Campaign.Model exposing (Model)
import Page.Campaign.Msg exposing (Msg(..))
import RemoteData exposing (RemoteData(..))
import Route
import Service.Draft.DraftService exposing (getDraftsByLevelId)
import Service.Level.LevelService exposing (getLevelsByCampaignId)
import String.Extra
import Update.HighScore exposing (getHighScoreByLevelId)
import Update.Solution exposing (getSolutionsByLevelId, getSolutionsByLevelIds)
import View.Box
import View.Constant exposing (color, size)
import View.ErrorScreen
import View.HighScore
import View.LevelButton
import View.LoadingScreen
import View.SingleSidebar
import ViewComponents


view : Session -> Model -> ( String, Element Msg )
view session model =
    let
        content =
            case getLevelsByCampaignId model.campaignId session of
                NotAsked ->
                    View.LoadingScreen.view "Not asked for campaign"

                Loading ->
                    View.LoadingScreen.view "Loading campaign"

                Failure error ->
                    View.ErrorScreen.view (GetError.toString error)

                Success levels ->
                    viewCampaign levels session model
    in
    ( "Campaign"
    , content
    )


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

        sidebar =
            case
                List.filter (.id >> Just >> (==) model.selectedLevelId) levels
                    |> List.head
            of
                Just level ->
                    viewSidebar session model level

                Nothing ->
                    viewTemporarySidebar <|
                        case getSolutionsByLevelIds (List.map .id levels) session of
                            NotAsked ->
                                [ text "Solutions not asked" ]

                            Loading ->
                                [ text "Loading solutions..." ]

                            Failure error ->
                                [ text "Error loading solutions"
                                , text (GetError.toString error)
                                ]

                            Success solutions ->
                                let
                                    numberOfSolvedLevels =
                                        List.map .levelId solutions
                                            |> List.Extra.unique
                                            |> List.length
                                in
                                [ String.concat
                                    [ String.fromInt numberOfSolvedLevels
                                    , "/"
                                    , List.length levels |> String.fromInt
                                    , " solved"
                                    ]
                                    |> text
                                ]

        mainContent =
            viewLevels session model levels
    in
    View.SingleSidebar.view
        { sidebar = sidebar
        , main = mainContent
        , session = session
        , modal = Nothing
        }


viewLevels : Session -> Model -> List Level -> Element Msg
viewLevels session model levels =
    let
        viewLevel level =
            let
                selected =
                    model.selectedLevelId
                        |> Maybe.map ((==) level.id)
                        |> Maybe.withDefault False

                solved =
                    getSolutionsByLevelId level.id session
                        |> RemoteData.toMaybe
                        |> Maybe.map (List.isEmpty >> not)
                        |> Maybe.withDefault False

                onPress =
                    Just (ClickedLevel level.id)

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
    List.sortBy .index levels
        |> List.map viewLevel
        |> wrappedRow
            [ spacing 20
            ]
        |> el []


viewSidebar : Session -> Model -> Level -> List (Element Msg)
viewSidebar session model level =
    let
        levelNameView =
            ViewComponents.viewTitle []
                level.name

        descriptionView =
            ViewComponents.descriptionTextbox
                []
                level.description

        solutionsRemoteData =
            getSolutionsByLevelId level.id session

        solvedStatusView =
            let
                solvedStatus =
                    case solutionsRemoteData of
                        NotAsked ->
                            "Solutions not asked"

                        Loading ->
                            "Loading solutions..."

                        Failure _ ->
                            "Error when loading solutions"

                        Success solutions ->
                            if List.isEmpty solutions then
                                "Not solved"

                            else
                                "Solved"
            in
            paragraph
                [ width fill
                , Font.center
                ]
                [ text solvedStatus
                ]

        highScoreView =
            if VerifiedAccessToken.isMissing session.accessToken then
                View.Box.simpleNonInteractive "Sign in to enable high scores"

            else
                case solutionsRemoteData of
                    NotAsked ->
                        View.Box.simpleNonInteractive "Solutions not asked"

                    Loading ->
                        View.Box.simpleNonInteractive "Loading solutions"

                    Failure error ->
                        View.Box.simpleError (GetError.toString error)

                    Success solutions ->
                        if List.isEmpty solutions then
                            View.Box.simpleNonInteractive "High scores hidden"

                        else
                            getHighScoreByLevelId level.id session
                                |> View.HighScore.view solutions

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
    case getDraftsByLevelId level.id session of
        NotAsked ->
            View.Box.simpleLoading "Not asked"

        Loading ->
            View.Box.simpleLoading "Loading drafts"

        Failure error ->
            View.Box.simpleError (GetError.toString error)

        Success drafts ->
            let
                newDraftButton =
                    ViewComponents.textButton
                        []
                        (Just ClickedGenerateDraft)
                        "New draft"

                viewDraft index draft =
                    let
                        maybeSolution =
                            getSolutionsByLevelId level.id session
                                |> RemoteData.toMaybe
                                |> Maybe.withDefault []
                                |> List.filter (.board >> (==) (History.current draft.boardHistory))
                                |> List.head

                        attrs =
                            [ width fill
                            , padding 10
                            , spacing 15
                            , Border.width 3
                            , color.border.default
                            , centerX
                            , mouseOver
                                [ color.background.hovering
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
            List.indexedMap viewDraft drafts
                |> (::) newDraftButton
                |> column
                    [ width fill
                    , spacing 20
                    ]
