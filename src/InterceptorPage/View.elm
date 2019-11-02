module InterceptorPage.View exposing (view)

import Data.Session exposing (Session)
import Html exposing (Html)
import InterceptorPage.Conflict.View as Conflict
import InterceptorPage.Initialize.View as Initialize
import InterceptorPage.Msg exposing (Msg(..))
import Maybe.Extra


first : List (a -> Maybe b) -> a -> Maybe b
first list a =
    case list of
        head :: tail ->
            head a
                |> Maybe.Extra.orElseLazy (\() -> first tail a)

        [] ->
            Nothing


view : Session -> Maybe ( String, Html Msg )
view session =
    first
        [ Conflict.view >> Maybe.map (Tuple.mapSecond ConflictMsg)
        , Initialize.view >> Maybe.map (Tuple.mapSecond InitializeMsg)
        ]
        session
