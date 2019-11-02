module InterceptorPage.Msg exposing (Msg(..))

import InterceptorPage.Conflict.Msg as Conflict
import InterceptorPage.Initialize.Msg as Initialize


type Msg
    = ConflictMsg Conflict.Msg
    | InitializeMsg Initialize.Msg
