module Data.History exposing
    ( History
    , back
    , current
    , first
    , forward
    , fromList
    , hasFuture
    , hasPast
    , last
    , map
    , push
    , singleton
    , size
    , toBeginning
    , toEnd
    , toList
    , toPastPresentFuture
    , update
    )


type alias History a =
    { past : List a
    , current : a
    , future : List a
    }


singleton : a -> History a
singleton a =
    { past = [], current = a, future = [] }


fromList : List a -> Maybe (History a)
fromList list =
    case list of
        head :: tail ->
            Just
                { past = []
                , current = head
                , future = tail
                }

        [] ->
            Nothing


toList : History a -> List a
toList history =
    List.concat
        [ List.reverse history.past
        , [ history.current ]
        , history.future
        ]


toPastPresentFuture : History a -> { past : List a, present : a, future : List a }
toPastPresentFuture history =
    { past = List.reverse history.past
    , present = history.current
    , future = history.future
    }


map : (a -> b) -> History a -> History b
map function history =
    { past = List.map function history.past
    , current = function history.current
    , future = List.map function history.future
    }


current : History a -> a
current =
    .current


hasPast : History a -> Bool
hasPast =
    not << List.isEmpty << .past


hasFuture : History a -> Bool
hasFuture =
    not << List.isEmpty << .future


back : History a -> History a
back history =
    case history.past of
        [] ->
            history

        nearPast :: distantPast ->
            { past = distantPast
            , current = nearPast
            , future = history.current :: history.future
            }


forward : History a -> History a
forward history =
    case history.future of
        [] ->
            history

        nearFuture :: distantFuture ->
            { past = history.current :: history.past
            , current = nearFuture
            , future = distantFuture
            }


push : a -> History a -> History a
push a history =
    { past = history.current :: history.past
    , current = a
    , future = []
    }


update : (a -> a) -> History a -> History a
update fn history =
    { history | current = fn history.current }


size : History a -> Int
size history =
    1 + List.length history.past + List.length history.future


first : History a -> a
first history =
    current (toBeginning history)


last : History a -> a
last history =
    current (toEnd history)


toBeginning : History a -> History a
toBeginning history =
    case history.past of
        [] ->
            history

        _ ->
            toBeginning (back history)


toEnd : History a -> History a
toEnd history =
    case history.future of
        [] ->
            history

        _ ->
            toEnd (forward history)
