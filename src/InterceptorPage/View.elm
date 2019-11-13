module InterceptorPage.View exposing (view)

import Data.Session exposing (Session)
import Html exposing (Html)
import InterceptorPage.AccessTokenExpired.View as AccessTokenExpired
import InterceptorPage.Conflict.View as Conflict
import InterceptorPage.Msg exposing (Msg(..))
import InterceptorPage.UnexpectedUserInfo.View as UnexpectedUserInfo
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
        [ AccessTokenExpired.view >> Maybe.map (Tuple.mapSecond AccessTokenExpiredMsg)
        , Conflict.view >> Maybe.map (Tuple.mapSecond ConflictMsg)
        , UnexpectedUserInfo.view >> Maybe.map (Tuple.mapSecond UnexpectedUserInfoMsg)
        ]
        session
