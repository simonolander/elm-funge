module Data.Blueprint exposing (Blueprint, loadAllFromServer, saveToServer)

import Api.GCP as GCP
import Data.AccessToken exposing (AccessToken)
import Data.DetailedHttpError exposing (DetailedHttpError)
import Data.Level as Level exposing (Level)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Json.Decode as Decode


type alias Blueprint =
    Level



-- REST


path : List String
path =
    [ "blueprints" ]


loadAllFromServer : AccessToken -> (Result DetailedHttpError (List Blueprint) -> msg) -> Cmd msg
loadAllFromServer accessToken toMsg =
    GCP.get (Decode.list Level.decoder)
        |> GCP.withPath path
        |> GCP.withAccessToken accessToken
        |> GCP.request toMsg


saveToServer : AccessToken -> (RequestResult Blueprint DetailedHttpError () -> msg) -> Blueprint -> Cmd msg
saveToServer accessToken toMsg blueprint =
    GCP.post (Decode.succeed ())
        |> GCP.withPath path
        |> GCP.withAccessToken accessToken
        |> GCP.withBody (Level.encode blueprint)
        |> GCP.request (RequestResult.constructor blueprint >> toMsg)
