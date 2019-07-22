module View.Header exposing (view)

import Api.Auth0
import Basics.Extra exposing (flip)
import Data.Cache as Cache
import Data.CampaignId as CampaignId
import Data.Session as Session
import Data.User as User
import Data.UserInfo as UserInfo
import Element exposing (..)
import Element.Background as Background
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Route


view session =
    let
        online =
            session.user
                |> User.getToken
                |> Maybe.Extra.isJust

        loginButton =
            link
                [ alignRight
                , padding 20
                , mouseOver
                    [ Background.color (rgb 0.5 0.5 0.5) ]
                ]
                (if online then
                    { url = Api.Auth0.logout
                    , label = text "Sign out"
                    }

                 else
                    { url = Api.Auth0.login (Just session.url)
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

        userInfo =
            session.user
                |> User.getUserInfo
                |> Maybe.map UserInfo.getUserName
                |> Maybe.map
                    (\userName ->
                        if online then
                            userName

                        else
                            userName ++ " (offline)"
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


parentRoute session =
    case Route.fromUrl session.url of
        Just Route.Home ->
            Nothing

        Just (Route.Campaign _ _) ->
            Just Route.Home

        Just (Route.EditDraft draftId) ->
            case
                session.drafts.local
                    |> Cache.get draftId
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
