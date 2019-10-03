module Update.General exposing (gotGetError, gotSaveError)

import Data.GetError as GetError exposing (GetError)
import Data.SaveError as SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import SessionUpdate exposing (SessionMsg)


gotSaveError : SaveError -> Session -> ( Session, Cmd SessionMsg )
gotSaveError saveError session =
    case saveError of
        SaveError.InvalidAccessToken _ ->
            ( Session.withoutAccessToken session
            , SaveError.consoleError saveError
            )

        _ ->
            ( session, SaveError.consoleError saveError )


gotGetError : GetError -> Session -> ( Session, Cmd SessionMsg )
gotGetError saveError session =
    case saveError of
        GetError.InvalidAccessToken _ ->
            ( Session.withoutAccessToken session
            , GetError.consoleError saveError
            )

        _ ->
            ( session, GetError.consoleError saveError )
