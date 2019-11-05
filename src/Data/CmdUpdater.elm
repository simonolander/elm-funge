module Data.CmdUpdater exposing (CmdUpdater, add, andThen, batch, id)

import Basics.Extra exposing (flip)
import Data.Updater exposing (Updater)


type alias CmdUpdater a msg =
    a -> ( a, Cmd msg )


id : CmdUpdater a msg
id =
    flip Tuple.pair Cmd.none


add : Cmd msg -> Updater ( a, Cmd msg )
add cmd2 ( a, cmd1 ) =
    ( a, Cmd.batch [ cmd1, cmd2 ] )


andThen : CmdUpdater a msg -> Updater ( a, Cmd msg )
andThen updater ( a, cmd ) =
    add cmd (updater a)


batch : List (CmdUpdater a msg) -> CmdUpdater a msg
batch updaters a =
    List.map andThen updaters
        |> List.foldl (flip (|>)) (id a)
