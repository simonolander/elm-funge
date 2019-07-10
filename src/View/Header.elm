module View.Header exposing (view)

import Api.Auth0
import Basics.Extra exposing (flip)
import Data.CampaignId as CampaignId
import Data.Session as Session
import Data.User as User
import Data.UserInfo as UserInfo
import Element exposing (..)
import Element.Background as Background
import RemoteData exposing (RemoteData(..))
import Route


view session =
    let
        loginButton =
            link
                [ alignRight
                , padding 20
                , mouseOver
                    [ Background.color (rgb 0.5 0.5 0.5) ]
                ]
                (if User.isLoggedIn session.user then
                    case User.getUserInfo session.user of
                        Success userInfo ->
                            { url = Api.Auth0.logout
                            , label = text ("Sign out " ++ UserInfo.getUserName userInfo)
                            }

                        _ ->
                            { url = Api.Auth0.logout
                            , label = text "Sign out"
                            }

                 else
                    { url = Api.Auth0.login session.url
                    , label = text "Sign in"
                    }
                )

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
    in
    row
        [ width fill
        , Background.color (rgb 0.1 0.1 0.1)
        ]
        [ backButton, loginButton ]


parentRoute session =
    case Route.fromUrl session.url of
        Just Route.Home ->
            Nothing

        Just (Route.Campaign _ _) ->
            Just Route.Home

        Just (Route.EditDraft draftId) ->
            case
                draftId
                    |> flip Session.getDraft session
                    |> RemoteData.toMaybe
                    |> Maybe.map .levelId
                    |> Maybe.map (flip Session.getLevel session)
                    |> Maybe.andThen RemoteData.toMaybe
            of
                Just level ->
                    Just (Route.Campaign level.campaignId (Just level.id))

                Nothing ->
                    Nothing

        Just (Route.ExecuteDraft draftId) ->
            Just (Route.EditDraft draftId)

        Just (Route.Blueprints _) ->
            Just Route.Home

        Just (Route.Blueprint levelId) ->
            Just (Route.Campaign CampaignId.blueprints (Just levelId))

        Just Route.Login ->
            Just Route.Home

        Nothing ->
            Nothing
