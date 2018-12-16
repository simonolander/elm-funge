module History exposing
    ( History
    , back
    , current
    , forward
    , hasFuture
    , hasPast
    , push
    , singleton
    )


type alias History a =
    { past : List a
    , current : a
    , future : List a
    }


singleton : a -> History a
singleton a =
    { past = [], current = a, future = [] }


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
