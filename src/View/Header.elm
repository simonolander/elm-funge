module View.Header exposing (view)

import Api.Auth0
import Basics.Extra exposing (flip)
import Data.CampaignId as CampaignId
import Data.Session exposing (Session)
import Data.UserInfo as UserInfo
import Data.VerifiedAccessToken as VerifiedAccessToken
import Element exposing (..)
import Element.Background as Background
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Route exposing (Route)
import Service.Draft.DraftService exposing (getDraftByDraftId)
import Service.Level.LevelService exposing (getLevelByLevelId)


view : Session -> Element msg
view session =
    let
        loginButton =
            let
                commonAttrs =
                    [ alignRight
                    , padding 20
                    ]

                linkAttrs =
                    commonAttrs
                        ++ [ mouseOver
                                [ Background.color (rgb 0.5 0.5 0.5) ]
                           ]
            in
            case session.accessToken of
                VerifiedAccessToken.None ->
                    link
                        linkAttrs
                        { url = Api.Auth0.login (Just session.url)
                        , label = text "Sign in"
                        }

                VerifiedAccessToken.Unverified _ ->
                    el commonAttrs (text "Verifying session")

                VerifiedAccessToken.Invalid _ ->
                    link
                        linkAttrs
                        { url = Api.Auth0.login (Just session.url)
                        , label = text "Re-sign in"
                        }

                VerifiedAccessToken.Valid _ ->
                    link
                        linkAttrs
                        { url = Api.Auth0.login (Just session.url)
                        , label = text "Sign in"
                        }

        backButton =
            case parentRoute session of
                Just route ->
                    Route.link
                        [ alignLeft
                        , padding 20
                        , mouseOver
                            [ Background.color (rgb 0.5 0.5 0.5) ]
                        ]
                        (text "< Back")
                        route

                Nothing ->
                    none

        userInfo =
            session.userInfo
                |> Maybe.map UserInfo.getUserName
                |> Maybe.map
                    (case session.accessToken of
                        VerifiedAccessToken.Valid _ ->
                            identity

                        VerifiedAccessToken.Invalid _ ->
                            flip (++) " (expired)"

                        VerifiedAccessToken.None ->
                            flip (++) " (offline)"

                        VerifiedAccessToken.Unverified _ ->
                            identity
                    )
                |> Maybe.withDefault "Guest"
                |> text
                |> el
                    [ alignRight
                    , padding 20
                    ]
    in
    row
        [ width fill
        , Background.color (rgb 0.1 0.1 0.1)
        ]
        [ backButton
        , userInfo
        , loginButton
        ]


parentRoute : Session -> Maybe Route
parentRoute session =
    case Route.fromUrl session.url of
        Just Route.Home ->
            Nothing

        Just (Route.Campaign _ _) ->
            Just Route.Campaigns

        Just Route.Campaigns ->
            Just Route.Home

        Just (Route.EditDraft draftId) ->
            case
                getDraftByDraftId draftId session
                    |> RemoteData.toMaybe
                    |> Maybe.Extra.join
                    |> Maybe.map .levelId
                    |> Maybe.map (flip getLevelByLevelId session)
                    |> Maybe.andThen RemoteData.toMaybe
                    |> Maybe.Extra.join
            of
                Just level ->
                    Just (Route.Campaign level.campaignId (Just level.id))

                Nothing ->
                    Just Route.Home

        Just (Route.ExecuteDraft draftId) ->
            Just (Route.EditDraft draftId)

        Just (Route.Blueprints _) ->
            Just Route.Home

        Just (Route.Blueprint levelId) ->
            Just (Route.Campaign CampaignId.blueprints (Just levelId))

        Just Route.Credits ->
            Just Route.Home

        Nothing ->
            Just Route.Home
