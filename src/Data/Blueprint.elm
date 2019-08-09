module Data.Blueprint exposing (Blueprint, loadAllFromServer, saveToServer)

import Api.GCP as GCP
import Data.AccessToken exposing (AccessToken)
import Data.GetError as GetError exposing (GetError)
import Data.Level as Level exposing (Level)
import Data.SaveError as SaveError exposing (SaveError)
import Json.Decode as Decode


type alias Blueprint =
    Level



-- REST


path : List String
path =
    [ "blueprints" ]


loadAllFromServer : AccessToken -> (Result GetError (List Blueprint) -> msg) -> Cmd msg
loadAllFromServer accessToken toMsg =
    GCP.get
        |> GCP.withPath path
        |> GCP.withAccessToken accessToken
        |> GCP.request (GetError.expect (Decode.list Level.decoder) toMsg)


saveToServer : AccessToken -> (Maybe SaveError -> msg) -> Blueprint -> Cmd msg
saveToServer accessToken toMsg blueprint =
    GCP.post
        |> GCP.withPath path
        |> GCP.withAccessToken accessToken
        |> GCP.withBody (Level.encode blueprint)
        |> GCP.request (SaveError.expect toMsg)
