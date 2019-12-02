module Data.SaveRequest exposing (SaveRequest(..), fromResponse)


type SaveRequest e a
    = Saving a
    | Error e
    | Saved a


fromResponse : a -> Maybe e -> SaveRequest e a
fromResponse value =
    Maybe.map Error >> Maybe.withDefault (Saved value)
