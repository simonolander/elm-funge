module Resource.LocalStorageService exposing
    ( LocalStorageInterface
    , expectedLocalStorageResponse
    , fromCurrentLocalStorageKey
    , fromExpectedLocalStorageKey
    , localStorageResponse
    , toCurrentLocalStorageKey
    , toExpectedLocalStorageKey
    , writeResourceToCurrentLocalStorage
    , writeResourceToExpectedLocalStorage
    )

import Data.CmdUpdater exposing (CmdUpdater)
import Data.Session exposing (Session)
import Data.Updater exposing (Updater)
import Either exposing (Either)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Json.Encode.Extra
import Ports.LocalStorage exposing (storageSetItem)
import Resource.ResourceType exposing (ResourceType, toLocalStoragePrefix)


type alias LocalStorageInterface id res a =
    { a
        | resourceType : ResourceType
        , idToString : id -> String
        , idFromString : String -> id
        , encode : res -> Encode.Value
        , decoder : Decoder res
        , setCurrentValue : id -> Maybe res -> Updater Session
        , setExpectedValue : id -> Maybe res -> Updater Session
    }



-- KEYS


toCurrentLocalStorageKey : LocalStorageInterface id res a -> id -> String
toCurrentLocalStorageKey interface id =
    String.join "." [ toLocalStoragePrefix interface.resourceType, interface.idToString id ]


fromCurrentLocalStorageKey : LocalStorageInterface id res a -> String -> Maybe id
fromCurrentLocalStorageKey interface localStorageKey =
    case String.split "." localStorageKey of
        prefix :: id :: [] ->
            if prefix == toLocalStoragePrefix interface.resourceType then
                Just (interface.idFromString id)

            else
                Nothing


toExpectedLocalStorageKey : LocalStorageInterface id res a -> id -> String
toExpectedLocalStorageKey interface id =
    String.join "." [ toCurrentLocalStorageKey interface id, "remote" ]


fromExpectedLocalStorageKey : LocalStorageInterface id res a -> String -> Maybe id
fromExpectedLocalStorageKey interface localStorageKey =
    case String.split "." localStorageKey of
        prefix :: id :: "remote" :: [] ->
            if prefix == toLocalStoragePrefix interface.resourceType then
                Just (interface.idFromString id)

            else
                Nothing



-- WRITE TO LOCAL STORAGE


writeResourceToCurrentLocalStorage : LocalStorageInterface id res a -> id -> Maybe res -> CmdUpdater Session msg
writeResourceToCurrentLocalStorage interface id maybeResource session =
    ( interface.setCurrentValue id maybeResource session
    , storageSetItem
        ( toCurrentLocalStorageKey interface id
        , Json.Encode.Extra.maybe interface.encode maybeResource
        )
    )


writeResourceToExpectedLocalStorage : LocalStorageInterface id res a -> id -> Maybe res -> CmdUpdater Session msg
writeResourceToExpectedLocalStorage interface id maybeResource session =
    ( interface.setExpectedValue id maybeResource session
    , storageSetItem
        ( toExpectedLocalStorageKey interface id
        , Json.Encode.Extra.maybe interface.encode maybeResource
        )
    )



-- READ FROM LOCAL STORAGE


localStorageResponse : LocalStorageInterface id res a -> ( String, Encode.Value ) -> Maybe (Either ( String, Decode.Error ) ( id, Maybe res ))
localStorageResponse interface ( key, value ) =
    case fromCurrentLocalStorageKey interface key of
        Just id ->
            Decode.decodeValue (Decode.nullable interface.decoder) value
                |> Either.fromResult
                |> Either.mapBoth (Tuple.pair key) (Tuple.pair id)
                |> Just

        Nothing ->
            Nothing


expectedLocalStorageResponse : LocalStorageInterface id res a -> ( String, Encode.Value ) -> Maybe (Either ( String, Decode.Error ) ( id, Maybe res ))
expectedLocalStorageResponse interface ( key, value ) =
    case fromExpectedLocalStorageKey interface key of
        Just id ->
            Decode.decodeValue (Decode.nullable interface.decoder) value
                |> Either.fromResult
                |> Either.mapBoth (Tuple.pair key) (Tuple.pair id)
                |> Just

        Nothing ->
            Nothing
