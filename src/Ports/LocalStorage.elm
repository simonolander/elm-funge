port module Ports.LocalStorage exposing (AndThen, Key, NewValue, OldValue, Value, storageClear, storageGetAndThen, storageGetItem, storageGetItemResponse, storageOnKeyAdded, storageOnKeyChanged, storageOnKeyRemoved, storagePushToSet, storageRemoveFromSet, storageRemoveItem, storageSetItem)


type alias Key =
    String


type alias Value =
    String


type alias NewValue =
    Value


type alias OldValue =
    Value


{-| Subscriptions (Receive from JS)
-}
port storageGetItemResponse : (( Key, Value ) -> msg) -> Sub msg


port storageOnKeyRemoved : (( Key, Value ) -> msg) -> Sub msg


port storageOnKeyAdded : (( Key, Value ) -> msg) -> Sub msg


port storageOnKeyChanged : (( Key, NewValue, OldValue ) -> msg) -> Sub msg


{-| Commands (Send to JS)
-}



-- Mapped to Storage API: https://developer.mozilla.org/en-US/docs/Web/API/Storage


port storageGetItem : Key -> Cmd msg


port storageSetItem : ( Key, Value ) -> Cmd msg


port storageRemoveItem : Key -> Cmd msg


port storageClear : () -> Cmd msg



-- Not in Storage API


port storagePushToSet : ( Key, Value ) -> Cmd msg


port storageRemoveFromSet : ( Key, Value ) -> Cmd msg


type alias AndThen =
    { prefix : Maybe String
    , concat : Bool
    }


port storageGetAndThen : ( Key, List Key, List AndThen ) -> Cmd msg
