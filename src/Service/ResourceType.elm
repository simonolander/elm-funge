module Service.ResourceType exposing
    ( ResourceType(..)
    , pluralize
    , toIdParameterName
    , toLocalStoragePrefix
    , toLower
    , toPath
    , toString
    )

import Basics.Extra exposing (flip)
import String exposing (append, toLower)


type ResourceType
    = Draft
    | Blueprint
    | Level
    | Campaign
    | Solution


toString : ResourceType -> String
toString resourceType =
    case resourceType of
        Draft ->
            "Draft"

        Blueprint ->
            "Blueprint"

        Level ->
            "Level"

        Campaign ->
            "Campaign"

        Solution ->
            "Solution"


toLower : ResourceType -> String
toLower =
    toString >> String.toLower


pluralize : ResourceType -> String
pluralize =
    toLower >> flip append "s"


toPath : ResourceType -> List String
toPath =
    pluralize >> List.singleton


toIdParameterName : ResourceType -> String
toIdParameterName =
    toLower >> flip append "Id"


toLocalStoragePrefix : ResourceType -> String.String
toLocalStoragePrefix =
    pluralize
