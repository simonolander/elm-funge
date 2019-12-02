module InterceptorPage.Conflict.Update exposing (update)

import Data.Cache as Cache
import Data.CmdUpdater exposing (CmdUpdater)
import Data.Draft as Draft
import Data.RemoteCache as RemoteCache
import Data.Session as Session exposing (Session)
import Data.Updater as Updater
import Debug exposing (todo)
import InterceptorPage.Conflict.Msg exposing (Msg(..), ObjectType(..))
import Ports.Console as Console
import RemoteData
import Resource.Blueprint.Update
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> CmdUpdater Session SessionMsg
update msg session =
    case msg of
        ClickedKeepLocal id objectType ->
            case objectType of
                Draft ->
                    todo ""

                Blueprint ->
                    Resource.Blueprint.Update.keepLocal id session

        ClickedKeepServer id objectType ->
            case objectType of
                Draft ->
                    case
                        Cache.get id session.drafts.actual
                            |> RemoteData.toMaybe
                    of
                        Just maybeDraft ->
                            ( Updater.batch
                                [ Session.updateDrafts (RemoteCache.withLocalValue id maybeDraft)
                                , Session.updateDrafts (RemoteCache.withExpectedValue id maybeDraft)
                                ]
                                session
                            , Cmd.batch
                                [ Draft.saveToLocalStorage id maybeDraft
                                , Draft.saveRemoteToLocalStorage id maybeDraft
                                ]
                            )

                        Nothing ->
                            ( session
                            , Console.errorString "d5833qlynutsdzxa    Clicked keep actual draft but there was no actual draft"
                            )

                Blueprint ->
                    Resource.Blueprint.Update.keepServer id session
