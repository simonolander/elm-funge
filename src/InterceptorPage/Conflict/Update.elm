module InterceptorPage.Conflict.Update exposing (update)

import Data.Blueprint as Blueprint
import Data.Cache as Cache
import Data.Draft as Draft
import Data.RemoteCache as RemoteCache
import Data.Session as Session exposing (Session)
import Data.Updater as Updater
import Dict
import InterceptorPage.Conflict.Msg exposing (Msg(..), ObjectType(..))
import Ports.Console as Console
import RemoteData
import Update.Blueprint
import Update.Draft
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> Session -> ( Session, Cmd SessionMsg )
update msg session =
    case msg of
        ClickedKeepLocal id objectType ->
            case objectType of
                Draft ->
                    case Dict.get id session.drafts.local of
                        Just (Just draft) ->
                            Update.Draft.saveDraft draft session

                        Just Nothing ->
                            Update.Draft.deleteDraft id session

                        Nothing ->
                            ( session
                            , Console.errorString "fv5lg9rrrd4utxwt    Clicked keep local draft but there was no local draft"
                            )

                Blueprint ->
                    case Dict.get id session.blueprints.local of
                        Just (Just blueprint) ->
                            Update.Blueprint.saveBlueprint blueprint session

                        Just Nothing ->
                            Update.Blueprint.deleteBlueprint id session

                        Nothing ->
                            ( session
                            , Console.errorString "fgzsgqrc0iqzpfds    Clicked keep local blueprint but there was no local blueprint"
                            )

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
                    case
                        Cache.get id session.blueprints.actual
                            |> RemoteData.toMaybe
                    of
                        Just maybeBlueprint ->
                            ( Updater.batch
                                [ Session.updateBlueprints (RemoteCache.withLocalValue id maybeBlueprint)
                                , Session.updateBlueprints (RemoteCache.withExpectedValue id maybeBlueprint)
                                ]
                                session
                            , Cmd.batch
                                [ Blueprint.saveToLocalStorage id maybeBlueprint
                                , Blueprint.saveRemoteToLocalStorage id maybeBlueprint
                                ]
                            )

                        Nothing ->
                            ( session
                            , Console.errorString "ad9oevcbxij6q9in    Clicked keep actual blueprint but there was no actual blueprint"
                            )
