module Extra.Cmd exposing (bind, fold, noCmd, withCmd, withExtraCmd)

import Basics.Extra exposing (flip)


withCmd : Cmd msg -> m -> ( m, Cmd msg )
withCmd =
    flip Tuple.pair


noCmd : m -> ( m, Cmd msg )
noCmd value =
    ( value, Cmd.none )


withExtraCmd : Cmd msg -> ( m, Cmd msg ) -> ( m, Cmd msg )
withExtraCmd cmd2 ( m, cmd1 ) =
    ( m, Cmd.batch [ cmd1, cmd2 ] )


bind : (m -> ( m, Cmd msg )) -> ( m, Cmd msg ) -> ( m, Cmd msg )
bind function ( value, cmd ) =
    withExtraCmd cmd (function value)


fold : List (m -> ( m, Cmd msg )) -> m -> ( m, Cmd msg )
fold functions model =
    functions
        |> List.map bind
        |> List.foldl (flip (|>)) (noCmd model)
