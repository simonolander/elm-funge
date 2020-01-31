module InterceptorPage.Conflict.Msg exposing (Msg(..))

import Resource.ResourceType exposing (ResourceType)


type alias Id =
    String


type Msg
    = ClickedKeepLocal Id ResourceType
    | ClickedKeepServer Id ResourceType
