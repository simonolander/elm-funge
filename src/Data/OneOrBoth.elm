module Data.OneOrBoth exposing (OneOrBoth(..), any, areSame, both, first, fromDicts, map, second)

import Basics.Extra exposing (uncurry)
import Dict
import List.Extra


type OneOrBoth a
    = First a
    | Second a
    | Both a a


fromDicts : Dict.Dict comparable v -> Dict.Dict comparable v -> List (OneOrBoth v)
fromDicts dictA dictB =
    List.concat [ Dict.keys dictA, Dict.keys dictB ]
        |> List.Extra.unique
        |> List.filterMap
            (\key ->
                case ( Dict.get key dictA, Dict.get key dictB ) of
                    ( Just a, Just b ) ->
                        Just (Both a b)

                    ( Just a, Nothing ) ->
                        Just (First a)

                    ( Nothing, Just b ) ->
                        Just (Second b)

                    ( Nothing, Nothing ) ->
                        Nothing
            )


map : (a -> b) -> OneOrBoth a -> OneOrBoth b
map function oneOrBoth =
    case oneOrBoth of
        First a ->
            First (function a)

        Second b ->
            Second (function b)

        Both a b ->
            Both (function a) (function b)


any : OneOrBoth a -> a
any oneOrBoth =
    case oneOrBoth of
        First a ->
            a

        Second b ->
            b

        Both a _ ->
            a


first : OneOrBoth a -> Maybe a
first oneOrBoth =
    case oneOrBoth of
        First a ->
            Just a

        Second _ ->
            Nothing

        Both a _ ->
            Just a


second : OneOrBoth a -> Maybe a
second oneOrBoth =
    case oneOrBoth of
        First _ ->
            Nothing

        Second b ->
            Just b

        Both _ b ->
            Just b


both : OneOrBoth a -> Maybe ( a, a )
both oneOrBoth =
    case oneOrBoth of
        First _ ->
            Nothing

        Second _ ->
            Nothing

        Both a b ->
            Just ( a, b )


areSame : (a -> a -> Bool) -> OneOrBoth a -> Bool
areSame eq =
    both >> Maybe.map (uncurry eq) >> Maybe.withDefault False
