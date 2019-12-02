port module Ports.LocalStorage exposing (Key, NewValue, OldValue, Value, decodeLocalStorageEntry, storageClear, storageGetAndThen, storageGetItem, storageGetItemResponse, storageOnKeyAdded, storageOnKeyChanged, storageOnKeyRemoved, storagePushToSet, storageRemoveFromSet, storageRemoveItem, storageSetItem)

import Json.Decode exposing (Decoder, Error, decodeValue)
import Json.Encode as Encode
import Maybe.Extra


type alias Key =
    String


type alias Value =
    Encode.Value


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


port storageGetAndThen : ( Key, List Key, List (Maybe String) ) -> Cmd msg


decodeLocalStorageEntry : (Key -> Maybe a) -> Decoder b -> ( Key, Value ) -> Maybe (Result ( Key, Error ) ( a, b ))
decodeLocalStorageEntry idFunction decoder ( key, value ) =
    case idFunction key of
        Just id ->
            decodeValue decoder value
                |> Result.map (Tuple.pair id)
                |> Result.mapError (Tuple.pair key)
                |> Just

        Nothing ->
            Nothing
