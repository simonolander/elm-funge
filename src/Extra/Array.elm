module Extra.Array exposing (member)

import Array exposing (..)


member : a -> Array a -> Bool
member value =
    Array.foldl ((||) << (==) value) False
