module Update.UserInfo exposing (gotLoadUserInfoResponse, loadUserInfo)

import Data.AccessToken as AccessToken exposing (AccessToken)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.GetError exposing (GetError)
import Data.Session exposing (Session)
import Data.UserInfo as UserInfo exposing (UserInfo)
import Data.VerifiedAccessToken as VerifiedAccessToken exposing (VerifiedAccessToken(..))
import Dict
import RemoteData exposing (RemoteData(..))
import Resource.Misc exposing (gotGetError)
import Update.SessionMsg exposing (SessionMsg(..))


loadUserInfo : CmdUpdater Session SessionMsg
loadUserInfo session =
    let
        load accessToken =
            ( { session | actualUserInfo = Loading }
            , UserInfo.loadFromServer accessToken GotLoadUserInfoResponse
            )
    in
    if RemoteData.isNotAsked session.actualUserInfo then
        VerifiedAccessToken.getAny session.accessToken
            |> Maybe.map load
            |> Maybe.withDefault ( session, Cmd.none )

    else
        ( session, Cmd.none )


{-| We got UserInfo response. If it was successful, it means that we have a valid access token in the session.
If the user info is the same as the last one, everything is fine, but otherwise we need to validate the data before continuing.
-}
gotLoadUserInfoResponse : AccessToken -> Result GetError UserInfo -> CmdUpdater Session SessionMsg
gotLoadUserInfoResponse accessToken result session =
    let
        sessionWithUserInfo =
            { session | actualUserInfo = RemoteData.fromResult result }

        withValidAccessToken sess_ =
            ( { sess_ | accessToken = Valid accessToken }
            , AccessToken.saveToLocalStorage accessToken
            )

        withExpectedUserInfo userInfo sess_ =
            ( { sess_ | expectedUserInfo = Just userInfo }
            , UserInfo.saveToLocalStorage userInfo
            )

        sessionIsClean =
            Dict.isEmpty sessionWithUserInfo.solutions.local
                && Dict.isEmpty sessionWithUserInfo.drafts.local
                && Dict.isEmpty sessionWithUserInfo.blueprints.local
    in
    case result of
        Ok actualUserInfo ->
            case sessionWithUserInfo.expectedUserInfo of
                Just expectedUserInfo ->
                    if expectedUserInfo.sub == actualUserInfo.sub then
                        withValidAccessToken sessionWithUserInfo

                    else if sessionIsClean then
                        CmdUpdater.batch
                            [ withValidAccessToken
                            , withExpectedUserInfo actualUserInfo
                            ]
                            sessionWithUserInfo

                    else
                        ( sessionWithUserInfo
                        , Cmd.none
                        )

                Nothing ->
                    if sessionIsClean then
                        CmdUpdater.batch
                            [ withValidAccessToken
                            , withExpectedUserInfo actualUserInfo
                            ]
                            sessionWithUserInfo

                    else
                        ( sessionWithUserInfo
                        , Cmd.none
                        )

        Err error ->
            gotGetError error sessionWithUserInfo
