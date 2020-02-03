module Data.Updater exposing (Updater, batch, makeFieldUpdater)

import Basics.Extra exposing (flip)


type alias Updater a =
    a -> a


batch : List (Updater a) -> Updater a
batch list a =
    List.foldl (flip (|>)) a list


makeFieldUpdater : (record -> field) -> (field -> Updater record) -> Updater field -> Updater record
makeFieldUpdater getter setter updater record =
    getter record
        |> updater
        |> flip setter record
