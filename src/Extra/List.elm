module Extra.List exposing (flist)

import List exposing (map)


flist : List (a -> b) -> a -> List b
flist list a =
    map ((|>) a) list
