module Data.SaveRequest exposing (SaveRequest(..))


type SaveRequest e a
    = Saving a
    | Error e
    | Saved a
