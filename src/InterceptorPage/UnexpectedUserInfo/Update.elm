module InterceptorPage.UnexpectedUserInfo.Update exposing (update)

import Api.Auth0 as Auth0
import Browser.Navigation
import Data.AccessToken as AccessToken
import Data.Blueprint as Blueprint
import Data.CmdUpdater exposing (CmdUpdater)
import Data.Draft as Draft
import Data.Session as Session exposing (Session)
import Data.Solution as Solution
import Data.UserInfo as UserInfo
import Data.VerifiedAccessToken exposing (VerifiedAccessToken(..))
import Dict
import InterceptorPage.UnexpectedUserInfo.Msg exposing (Msg(..))
import RemoteData
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> CmdUpdater Session SessionMsg
update msg session =
    case msg of
        ClickedDeleteLocalData ->
            case ( session.accessToken, RemoteData.toMaybe session.actualUserInfo ) of
                ( Unverified accessToken, Just actualUserInfo ) ->
                    ( Session.init session.key session.url
                        |> Session.withAccessToken (Valid accessToken)
                        |> Session.withExpectedUserInfo (Just actualUserInfo)
                    , Cmd.batch
                        [ Dict.keys session.drafts.local
                            |> List.map Draft.removeFromLocalStorage
                            |> Cmd.batch
                        , Dict.keys session.drafts.expected
                            |> List.map Draft.removeRemoteFromLocalStorage
                            |> Cmd.batch
                        , Dict.keys session.blueprints.local
                            |> List.map Blueprint.removeFromLocalStorage
                            |> Cmd.batch
                        , Dict.keys session.blueprints.expected
                            |> List.map Blueprint.removeRemoteFromLocalStorage
                            |> Cmd.batch
                        , Dict.keys session.solutions.local
                            |> List.map Solution.removeFromLocalStorage
                            |> Cmd.batch
                        , Dict.keys session.solutions.expected
                            |> List.map Solution.removeRemoteFromLocalStorage
                            |> Cmd.batch
                        , AccessToken.saveToLocalStorage accessToken
                        , UserInfo.saveToLocalStorage actualUserInfo
                        ]
                    )

                _ ->
                    ( session, Cmd.none )

        ClickedSignInToOtherAccount ->
            ( session
            , Browser.Navigation.load (Auth0.reLogin (Just session.url))
            )

        ClickedImportLocalData ->
            case ( session.accessToken, RemoteData.toMaybe session.actualUserInfo ) of
                ( Unverified accessToken, Just actualUserInfo ) ->
                    ( { session
                        | accessToken = Valid accessToken
                        , userInfo = Just actualUserInfo
                      }
                    , Cmd.batch
                        [ AccessToken.saveToLocalStorage accessToken
                        , UserInfo.saveToLocalStorage actualUserInfo
                        ]
                    )

                _ ->
                    ( session, Cmd.none )
