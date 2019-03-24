module Api exposing (getLevels)

import Http
import Model exposing (..)


getLevels : Cmd Msg
getLevels =
    Http.get
        { url = "https://us-central1-luminous-cubist-234816.cloudfunctions.net/levels"
        , expect = Http.expectWhatever (always (ApiMsg GetLevelsMsg))
        }