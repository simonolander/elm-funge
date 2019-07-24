module Extra.Cmd exposing (bind, fold, mapModel, withCmd, withExtraCmd, withNone)

import Basics.Extra exposing (flip)


withCmd : Cmd msg -> m -> ( m, Cmd msg )
withCmd cmd value =
    ( value, cmd )


withNone : m -> ( m, Cmd msg )
withNone value =
    ( value, Cmd.none )


withExtraCmd : ( m, Cmd msg ) -> Cmd msg -> ( m, Cmd msg )
withExtraCmd ( m, cmd1 ) cmd2 =
    ( m, Cmd.batch [ cmd1, cmd2 ] )


mapModel : (m1 -> m2) -> ( m1, Cmd msg ) -> ( m2, Cmd msg )
mapModel =
    Tuple.mapFirst


bind : (m -> ( m, Cmd msg )) -> ( m, Cmd msg ) -> ( m, Cmd msg )
bind function ( value, cmd ) =
    withExtraCmd (function value) cmd


fold : List (m -> ( m, Cmd msg )) -> ( m, Cmd msg ) -> ( m, Cmd msg )
fold functions acc =
    functions
        |> List.map bind
        |> List.foldl (flip (|>)) acc
