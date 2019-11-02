module InterceptorPage.Conflict.Msg exposing (Msg(..), ObjectType(..))


type alias Id =
    String


type ObjectType
    = Draft
    | Blueprint


type Msg
    = ClickedKeepLocal Id ObjectType
    | ClickedKeepServer Id ObjectType
