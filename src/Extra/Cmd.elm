module Extra.Cmd exposing (bind, fold, mapModel, noCmd, withCmd, withExtraCmd)

import Basics.Extra exposing (flip)


withCmd : Cmd msg -> m -> ( m, Cmd msg )
withCmd cmd value =
    ( value, cmd )


noCmd : m -> ( m, Cmd msg )
noCmd value =
    ( value, Cmd.none )


withExtraCmd : Cmd msg -> ( m, Cmd msg ) -> ( m, Cmd msg )
withExtraCmd cmd2 ( m, cmd1 ) =
    ( m, Cmd.batch [ cmd1, cmd2 ] )


mapModel : (m1 -> m2) -> ( m1, Cmd msg ) -> ( m2, Cmd msg )
mapModel =
    Tuple.mapFirst


bind : (m -> ( m, Cmd msg )) -> ( m, Cmd msg ) -> ( m, Cmd msg )
bind function ( value, cmd ) =
    withExtraCmd cmd (function value)


fold : List (m -> ( m, Cmd msg )) -> ( m, Cmd msg ) -> ( m, Cmd msg )
fold functions acc =
    functions
        |> List.map bind
        |> List.foldl (flip (|>)) acc
