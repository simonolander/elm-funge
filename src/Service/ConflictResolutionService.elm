module Resource.ConflictResolutionService exposing
    ( Resolution(..)
    , getConflictResolution
    , resolveConflict
    , resolveManuallyKeepLocal
    , resolveManuallyKeepServer
    , toConflict
    )

import Basics.Extra exposing (flip)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.OneOrBoth exposing (OneOrBoth(..))
import Data.Session exposing (Session)
import Dict
import Maybe.Extra
import Ports.Console as Console
import RemoteData
import Resource.LocalStorageService exposing (LocalStorageInterface, writeResourceToCurrentLocalStorage, writeResourceToExpectedLocalStorage)
import Resource.ModifiableResource exposing (ModifiableRemoteResource)
import Service.ModifyResourceService exposing (writeResourceToServer)
import Update.SessionMsg exposing (SessionMsg)


type alias DetermineConflictInterface id res comparable a b =
    { a
        | getResource : Session -> ModifiableRemoteResource comparable res b
        , toKey : id -> comparable
        , equals : res -> res -> Bool
    }


type alias ResolveConflictInterface id res comparable a =
    DetermineConflictInterface id res comparable a (LocalStorageInterface id res {})



-- CONFLICT RESOLUTION


type Resolution data
    = Merge (Maybe data) Bool Bool Bool
    | Conflict (OneOrBoth data)


toConflict : Resolution a -> Maybe (OneOrBoth a)
toConflict resolution =
    case resolution of
        Merge _ _ _ _ ->
            Nothing

        Conflict oneOrBoth ->
            Just oneOrBoth


getConflictResolution : DetermineConflictInterface id res comparable a b -> id -> Maybe res -> Session -> Resolution res
getConflictResolution interface id maybeActual session =
    let
        maybeLocal =
            interface.getResource session
                |> .local
                |> Dict.get (interface.toKey id)

        maybeExpected =
            interface.getResource session
                |> .expected
                |> Dict.get (interface.toKey id)

        equals =
            interface.equals
    in
    case ( maybeLocal, maybeExpected, maybeActual ) of
        ( Just (Just local), Just (Just expected), Just actual ) ->
            if equals local expected then
                -- 1 1 !
                Merge (Just actual) True True False

            else if equals local actual then
                -- 1 2 1
                Merge (Just actual) False True False

            else if equals expected actual then
                -- 1 2 2
                Merge (Just local) False False True

            else
                -- 1 2 3
                Conflict (Both local actual)

        ( Just (Just local), Just (Just expected), Nothing ) ->
            if equals local expected then
                -- 1 1 0
                Merge Nothing True True False

            else
                -- 1 2 0
                Conflict (First local)

        ( Just (Just local), Just Nothing, Just actual ) ->
            if equals local actual then
                -- 1 0 1
                Merge (Just actual) False True False

            else
                -- 1 0 2
                Conflict (Both local actual)

        ( Just (Just local), Just Nothing, Nothing ) ->
            -- 1 0 0
            Merge (Just local) False False True

        ( Just (Just local), Nothing, Just actual ) ->
            if equals local actual then
                -- 1 ? 1
                Merge (Just actual) False True False

            else
                -- 1 ? 2
                Conflict (Both local actual)

        ( Just (Just local), Nothing, Nothing ) ->
            -- 1 0 0
            Merge (Just local) False False True

        ( Just Nothing, Just (Just expected), Just actual ) ->
            if equals expected actual then
                -- 0 1 1
                Merge Nothing False False True

            else
                -- 0 1 2
                Conflict (Second actual)

        ( Just Nothing, Just Nothing, Just actual ) ->
            -- 0 0 1
            Merge (Just actual) True True False

        ( Just Nothing, _, Nothing ) ->
            -- 0 ! 0
            Merge Nothing True True False

        ( Just Nothing, Nothing, Just actual ) ->
            -- 0 ? 1
            Conflict (Second actual)

        ( Nothing, _, actual ) ->
            -- ? ! !
            Merge actual True True False


resolveConflict : ResolveConflictInterface id res comparable a -> id -> Maybe res -> CmdUpdater Session SessionMsg
resolveConflict interface id maybeActual session =
    flip CmdUpdater.batch session <|
        case getConflictResolution interface id maybeActual session of
            Merge data shouldWriteLocal shouldWriteExpected shouldWriteActual ->
                Maybe.Extra.values
                    [ if shouldWriteLocal then
                        Just (writeResourceToCurrentLocalStorage interface id data)

                      else
                        Nothing
                    , if shouldWriteExpected then
                        Just (writeResourceToExpectedLocalStorage interface id data)

                      else
                        Nothing
                    , if shouldWriteActual then
                        Just (writeResourceToServer interface id data)

                      else
                        Nothing
                    ]

            Conflict _ ->
                []


resolveManuallyKeepLocal : ResolveConflictInterface id res comparable a -> comparableId -> CmdUpdater Session SessionMsg
resolveManuallyKeepLocal interface id session =
    case
        interface.getResource session
            |> .local
            |> Dict.get id
    of
        Just maybeResource ->
            writeResourceToServer interface id maybeResource session

        Nothing ->
            ( session
            , Console.errorString "32IY3Wkb    Cannot keep local resource: nothing to keep"
            )


resolveManuallyKeepServer : ResolveConflictInterface id res comparable a -> comparableId -> CmdUpdater Session SessionMsg
resolveManuallyKeepServer interface id session =
    case
        interface.getResource session
            |> .actual
            |> Dict.get id
            |> Maybe.andThen RemoteData.toMaybe
    of
        Just maybeResource ->
            CmdUpdater.batch
                [ writeResourceToCurrentLocalStorage interface id maybeResource
                , writeResourceToExpectedLocalStorage interface id maybeResource
                ]
                session

        Nothing ->
            ( session
            , Console.errorString "taNV569E    Cannot keep server resource, it's not successfully loaded."
            )
