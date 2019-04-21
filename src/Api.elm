module Api exposing (getDrafts, getLevels)

import Data.AuthorizationToken as AuthorizationToken exposing (AuthorizationToken)
import Data.Draft as Draft exposing (Draft)
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.User exposing (User)
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
        , expect = Http.expectJson toMsg (Decode.maybe Level.decoder)
        }


getDrafts : AuthorizationToken -> List LevelId -> (Result Http.Error (List Draft) -> msg) -> Cmd msg
getDrafts token levelIds toMsg =
    let
        url =
            levelIds
                |> String.join ","
                |> Url.Builder.string "levelIds"
                |> List.singleton
                |> Url.Builder.crossOrigin gcpPrePath [ "drafts" ]

        expect =
            Http.expectJson toMsg (Decode.list Draft.decoder)
    in
    authorizedGet url token expect



-- PRIVATE


gcpPrePath : String
gcpPrePath =
    "https://us-central1-luminous-cubist-234816.cloudfunctions.net"


authorizationHeader : AuthorizationToken -> Http.Header
authorizationHeader token =
    Http.header "Authorization" ("Bearer " ++ AuthorizationToken.toString token)


authorizedGet : String -> AuthorizationToken -> Http.Expect msg -> Cmd msg
authorizedGet url token function =
    Http.request
        { method = "GET"
        , headers = [ authorizationHeader token ]
        , url = url
        , body = Http.emptyBody
        , expect = function
        , timeout = Nothing
        , tracker = Nothing
        }
