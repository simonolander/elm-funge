module Resource.ResourceType exposing
    ( ResourceType(..)
    , pluralize
    , toIdParameterName
    , toLocalStoragePrefix
    , toPath
    , toString
    )

import Basics.Extra exposing (flip)
import String exposing (toLower)


type ResourceType
    = Draft
    | Blueprint
    | Level


toString : ResourceType -> String
toString resourceType =
    case resourceType of
        Draft ->
            "Draft"

        Blueprint ->
            "Blueprint"

        Level ->
            "Level"


pluralize : ResourceType -> String
pluralize =
    toString >> toLower >> flip append "s"


toPath : ResourceType -> List String
toPath =
    pluralize >> List.singleton


toIdParameterName : ResourceType -> String
toIdParameterName =
    toString >> toLower >> flip append "Id"


toLocalStoragePrefix : ResourceType -> String.String
toLocalStoragePrefix =
    pluralize
