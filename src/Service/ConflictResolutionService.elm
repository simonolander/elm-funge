module Service.ConflictResolutionService exposing
    ( Resolution(..)
    , getAllManualConflicts
    , getConflictResolution
    , resolveConflict
    , resolveManuallyKeepLocalResource
    , resolveManuallyKeepServerResource
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
import Service.LocalStorageService exposing (LocalStorageInterface, writeResourceToCurrentLocalStorage, writeResourceToExpectedLocalStorage)
import Service.ModifiableRemoteResource as ModifiableRemoteResource exposing (ModifiableRemoteResource)
import Service.ModifyResourceService exposing (writeResourceToServer)
import Service.RemoteDataDict as RemoteDataDict
import Update.SessionMsg exposing (SessionMsg)


type alias DetermineConflictInterface id res comparable a b =
    { b
        | getRemoteResource : Session -> ModifiableRemoteResource comparable res a
        , toKey : id -> comparable
        , fromKey : comparable -> id
        , equals : res -> res -> Bool
    }


type alias ResolveConflictInterface id res comparable a b =
    DetermineConflictInterface id res comparable a (LocalStorageInterface id res b)



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


getAllManualConflicts : DetermineConflictInterface id res comparable a b -> Session -> List (OneOrBoth res)
getAllManualConflicts i session =
    let
        getConflict id =
            case
                i.getRemoteResource session
                    |> .actual
                    |> RemoteDataDict.get id
                    |> RemoteData.toMaybe
            of
                Just actual ->
                    getConflictResolution i (i.fromKey id) actual session
                        |> toConflict

                Nothing ->
                    Nothing
    in
    i.getRemoteResource session
        |> ModifiableRemoteResource.getAllIds
        |> List.filterMap getConflict


getConflictResolution : DetermineConflictInterface id res comparable a b -> id -> Maybe res -> Session -> Resolution res
getConflictResolution i id maybeActual session =
    let
        maybeLocal =
            i.getRemoteResource session
                |> .local
                |> Dict.get (i.toKey id)

        maybeExpected =
            i.getRemoteResource session
                |> .expected
                |> Dict.get (i.toKey id)

        equals =
            i.equals
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


resolveConflict : ResolveConflictInterface id res comparable a b -> id -> Maybe res -> CmdUpdater Session SessionMsg
resolveConflict i id maybeActual session =
    flip CmdUpdater.batch session <|
        case getConflictResolution i id maybeActual session of
            Merge data shouldWriteLocal shouldWriteExpected shouldWriteActual ->
                Maybe.Extra.values
                    [ if shouldWriteLocal then
                        Just (writeResourceToCurrentLocalStorage i id data)

                      else
                        Nothing
                    , if shouldWriteExpected then
                        Just (writeResourceToExpectedLocalStorage i id data)

                      else
                        Nothing
                    , if shouldWriteActual then
                        Just (writeResourceToServer i id data)

                      else
                        Nothing
                    ]

            Conflict _ ->
                []


resolveManuallyKeepLocalResource : ResolveConflictInterface id res comparable a b -> id -> CmdUpdater Session SessionMsg
resolveManuallyKeepLocalResource i id session =
    case
        i.getRemoteResource session
            |> .local
            |> Dict.get (i.toKey id)
    of
        Just maybeResource ->
            writeResourceToServer i id maybeResource session

        Nothing ->
            ( session
            , Console.errorString "32IY3Wkb    Cannot keep local resource: nothing to keep"
            )


resolveManuallyKeepServerResource : ResolveConflictInterface id res comparable a b -> id -> CmdUpdater Session SessionMsg
resolveManuallyKeepServerResource i id session =
    case
        i.getRemoteResource session
            |> .actual
            |> Dict.get (i.toKey id)
            |> Maybe.andThen RemoteData.toMaybe
    of
        Just maybeResource ->
            CmdUpdater.batch
                [ writeResourceToCurrentLocalStorage i id maybeResource
                , writeResourceToExpectedLocalStorage i id maybeResource
                ]
                session

        Nothing ->
            ( session
            , Console.errorString "taNV569E    Cannot keep server resource, it's not successfully loaded."
            )
