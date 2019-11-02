module Data.Updater exposing (Updater, batch)

import Basics.Extra exposing (flip)


type alias Updater a =
    a -> a


batch : List (Updater a) -> Updater a
batch list a =
    List.foldl (flip (|>)) a list
