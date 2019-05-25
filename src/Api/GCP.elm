module Api.GCP exposing (get, getDrafts, getLevels, getUserInfo, publishSolution, saveDraft, verifyIdentityToken)

import Data.AuthorizationToken as AuthorizationToken exposing (AuthorizationToken)
import Data.Draft as Draft exposing (Draft)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Solution as Solution exposing (Solution)
import Data.UserInfo as UserInfo exposing (UserInfo)
import Http exposing (Expect, Header)
import Json.Decode as Decode
import Json.Encode as Encode
import Result exposing (Result)
import Url.Builder



-- PUBLIC


getLevels : (Result Http.Error (List Level) -> msg) -> Cmd msg
getLevels toMsg =
    Http.get
        { url = Url.Builder.crossOrigin gcpPrePath [ "levels" ] []
        , expect = Http.expectJson toMsg (Decode.list Level.decoder)
        }


getLevel : LevelId -> (Result Http.Error (Maybe Level) -> msg) -> Cmd msg
getLevel levelId toMsg =
    Http.get
        { url = Url.Builder.crossOrigin gcpPrePath [ "levels" ] [ Url.Builder.string "levelId" levelId ]
        , expect = Http.expectJson toMsg (Decode.nullable Level.decoder)
        }


getDrafts : AuthorizationToken -> (Result Http.Error (List Draft) -> msg) -> Cmd msg
getDrafts token toMsg =
    let
        url =
            Url.Builder.crossOrigin gcpPrePath [ "drafts" ] []

        expect =
            Http.expectJson toMsg (Decode.list Draft.decoder)
    in
    authorizedGet url token expect


saveDraft : AuthorizationToken -> Draft -> (Result Http.Error () -> msg) -> Cmd msg
saveDraft token draft toMsg =
    let
        url =
            Url.Builder.crossOrigin gcpPrePath [ "drafts" ] []

        expect =
            Http.expectWhatever toMsg

        body =
            Draft.encode draft
    in
    authorizedPost url token body expect


publishSolution : AuthorizationToken -> Solution -> (Result Http.Error () -> msg) -> Cmd msg
publishSolution token solution toMsg =
    let
        url =
            Url.Builder.crossOrigin gcpPrePath [ "solutions" ] []

        expect =
            Http.expectWhatever toMsg

        body =
            Solution.encode solution
    in
    authorizedPost url token body expect


getUserInfo : AuthorizationToken -> (Result Http.Error UserInfo -> msg) -> Cmd msg
getUserInfo authorizationToken toMsg =
    let
        url =
            Url.Builder.crossOrigin gcpPrePath [ "userInfo" ] []

        expect =
            Http.expectJson toMsg UserInfo.decoder
    in
    authorizedGet url authorizationToken expect


verifyIdentityToken : AuthorizationToken -> (Result Http.Error () -> msg) -> Cmd msg
verifyIdentityToken authorizationToken toMsg =
    let
        url =
            Url.Builder.crossOrigin gcpPrePath [ "userInfo" ] []

        expect =
            Http.expectWhatever toMsg
    in
    authorizedGet url authorizationToken expect


get : List String -> List Url.Builder.QueryParameter -> Decode.Decoder a -> (Result Http.Error a -> msg) -> Cmd msg
get path queryParameters decoder toMsg =
    let
        url =
            buildUrl path queryParameters

        expect =
            Http.expectJson toMsg decoder
    in
    Http.get
        { url = url
        , expect = expect
        }



-- PRIVATE


buildUrl : List String -> List Url.Builder.QueryParameter -> String
buildUrl =
    Url.Builder.crossOrigin gcpPrePath


gcpPrePath : String
gcpPrePath =
    "https://us-central1-luminous-cubist-234816.cloudfunctions.net"


authorizationHeader : AuthorizationToken -> Http.Header
authorizationHeader token =
    Http.header "Authorization" ("Bearer " ++ AuthorizationToken.toString token)


authorizedGet : String -> AuthorizationToken -> Http.Expect msg -> Cmd msg
authorizedGet url token expect =
    Http.request
        { method = "GET"
        , headers = [ authorizationHeader token ]
        , url = url
        , body = Http.emptyBody
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }


authorizedPost : String -> AuthorizationToken -> Encode.Value -> Http.Expect msg -> Cmd msg
authorizedPost url token body expect =
    Http.request
        { method = "POST"
        , headers = [ authorizationHeader token ]
        , url = url
        , body = Http.jsonBody body
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }
