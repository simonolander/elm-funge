module Extra.Tuple exposing (fanout)


fanout : (a -> b) -> (a -> c) -> a -> ( b, c )
fanout f1 f2 a =
    ( f1 a, f2 a )
