module Data.Blueprint exposing (Blueprint, loadAllFromServer, saveToServer)

import Api.GCP as GCP
import Data.AccessToken exposing (AccessToken)
import Data.Level as Level exposing (Level)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Http
import Json.Decode as Decode


type alias Blueprint =
    Level



-- REST


path : List String
path =
    [ "blueprints" ]


loadAllFromServer : AccessToken -> (Result Http.Error (List Blueprint) -> msg) -> Cmd msg
loadAllFromServer accessToken toMsg =
    GCP.authorizedGet path [] (Decode.list Level.decoder) toMsg accessToken


saveToServer : AccessToken -> (RequestResult Blueprint Http.Error () -> msg) -> Blueprint -> Cmd msg
saveToServer accessToken toMsg blueprint =
    GCP.post accessToken path [] (Http.expectWhatever (RequestResult.constructor blueprint >> toMsg)) (Level.encode blueprint)
