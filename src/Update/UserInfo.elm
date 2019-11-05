module Update.UserInfo exposing (gotLoadUserInfoResponse, loadUserInfo)

import Data.GetError exposing (GetError)
import Data.Session as Session exposing (Session)
import Data.UserInfo as UserInfo exposing (UserInfo)
import Data.VerifiedAccessToken as VerifiedAccessToken exposing (VerifiedAccessToken(..))
import RemoteData exposing (RemoteData(..))
import Update.General exposing (gotGetError)
import Update.SessionMsg exposing (SessionMsg(..))


loadUserInfo : Session -> ( Session, Cmd SessionMsg )
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


gotLoadUserInfoResponse : Result GetError UserInfo -> Session -> ( Session, Cmd SessionMsg )
gotLoadUserInfoResponse result session =
    let
        sessionWithUserInfo =
            { session | actualUserInfo = RemoteData.fromResult result }
    in
    case result of
        Ok _ ->
            ( Session.updateAccessToken VerifiedAccessToken.validate sessionWithUserInfo
            , Cmd.none
            )

        Err error ->
            gotGetError error sessionWithUserInfo
