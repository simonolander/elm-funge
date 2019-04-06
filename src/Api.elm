module Api exposing (getLevels)

import Http


getLevels : (a -> msg) -> Cmd msg
getLevels toMsg =
    Http.get
        { url = "https://us-central1-luminous-cubist-234816.cloudfunctions.net/levels"
        , expect = Http.expectWhatever toMsg
        }
