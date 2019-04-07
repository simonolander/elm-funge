module Api exposing (getLevels)

import Data.Level as Level exposing (Level)
import Http
import Json.Decode as Decode


getLevels : (Result Http.Error (List Level) -> msg) -> Cmd msg
getLevels toMsg =
    Http.get
        { url = "https://us-central1-luminous-cubist-234816.cloudfunctions.net/levels"
        , expect = Http.expectJson toMsg (Decode.list Level.decoder)
        }
