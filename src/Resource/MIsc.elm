module Resource.MIsc exposing (ResourceInterface, resolveConflict)

import Basics.Extra exposing (flip)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)


type alias ResourceInterface data resource msg =
    { maybeLocal : Maybe (Maybe data)
    , maybeExpected : Maybe (Maybe data)
    , maybeActual : Maybe data
    , writeLocal : Maybe data -> CmdUpdater resource msg
    , writeExpected : Maybe data -> CmdUpdater resource msg
    , writeActual : Maybe data -> CmdUpdater resource msg
    , equals : data -> data -> Bool
    }


resolveConflict : ResourceInterface data resource msg -> CmdUpdater resource msg
resolveConflict interface resource =
    let
        { maybeLocal, maybeExpected, maybeActual, writeLocal, writeExpected, writeActual, equals } =
            interface
    in
    flip CmdUpdater.batch resource <|
        case ( maybeLocal, maybeExpected, maybeActual ) of
            ( Just (Just local), Just (Just expected), Just actual ) ->
                if equals local expected then
                    -- 1 1 !
                    [ writeLocal (Just actual), writeExpected (Just actual) ]

                else if equals local actual then
                    -- 1 2 1
                    [ writeExpected (Just actual) ]

                else if equals expected actual then
                    -- 1 2 2
                    [ writeActual (Just local) ]

                else
                    -- 1 2 3
                    []

            ( Just (Just local), Just (Just expected), Nothing ) ->
                if equals local expected then
                    -- 1 1 0
                    [ writeLocal Nothing, writeExpected Nothing ]

                else
                    -- 1 2 0
                    []

            ( Just (Just local), Just Nothing, Just actual ) ->
                if equals local actual then
                    -- 1 0 1
                    [ writeExpected (Just actual) ]

                else
                    -- 1 0 2
                    []

            ( Just (Just local), Nothing, Just actual ) ->
                if equals local actual then
                    -- 1 ? 1
                    [ writeExpected (Just actual) ]

                else
                    -- 1 ? 2
                    []

            ( Just (Just local), Nothing, Nothing ) ->
                -- 1 0 0
                [ writeActual (Just local) ]

            ( Just Nothing, Just (Just expected), Just actual ) ->
                if equals expected actual then
                    -- 0 1 1
                    [ writeExpected Nothing, writeActual Nothing ]

                else
                    -- 0 1 2
                    []

            ( Just Nothing, Just Nothing, Just actual ) ->
                -- 0 0 1
                [ writeLocal (Just actual), writeExpected (Just actual) ]

            ( Just Nothing, _, Nothing ) ->
                -- 0 ! 0
                [ writeLocal Nothing, writeExpected Nothing ]

            ( Just Nothing, Nothing, Just _ ) ->
                -- 0 ? 1
                []

            ( Just Nothing, Nothing, Nothing ) ->
                -- 0 ? 0
                [ writeExpected Nothing ]

            ( Nothing, _, actual ) ->
                -- ? ! !
                [ writeLocal actual, writeExpected actual ]
