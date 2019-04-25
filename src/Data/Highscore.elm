module Data.Highscore exposing (Highscore)

import Dict exposing (Dict)


type alias Highscore =
    { numberOfSteps : Dict Int Int
    , numberOfInstructions : Dict Int Int
    }
