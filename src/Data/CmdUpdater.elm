module Data.CmdUpdater exposing (CmdUpdater, add, andThen, batch, id, mapBoth, mapCmd, mapModel, mapSession, withCmd, withModel, withSession)

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


mapSession : (a -> x) -> ( ( a, b ), c ) -> ( ( x, b ), c )
mapSession =
    Tuple.mapFirst >> Tuple.mapFirst


mapModel : (b -> y) -> ( ( a, b ), c ) -> ( ( a, y ), c )
mapModel =
    Tuple.mapSecond >> Tuple.mapFirst


mapCmd : (msg1 -> msg2) -> ( a, Cmd msg1 ) -> ( a, Cmd msg2 )
mapCmd =
    Cmd.map >> Tuple.mapSecond


mapBoth : (a -> b) -> (msg1 -> msg2) -> ( a, Cmd msg1 ) -> ( b, Cmd msg2 )
mapBoth f1 =
    Cmd.map >> Tuple.mapBoth f1


withModel : b -> ( a, c ) -> ( ( a, b ), c )
withModel =
    flip Tuple.pair >> Tuple.mapFirst


withSession : a -> ( b, c ) -> ( ( a, b ), c )
withSession =
    Tuple.pair >> Tuple.mapFirst


withCmd : b -> a -> ( a, b )
withCmd =
    flip Tuple.pair
