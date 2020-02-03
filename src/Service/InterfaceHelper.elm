module Service.InterfaceHelper exposing (createModifiableRemoteResourceInterface, createRemoteResourceInterface)

import Basics.Extra exposing (flip)
import Data.CmdUpdater exposing (CmdUpdater)
import Data.GetError exposing (GetError)
import Data.SaveError exposing (SaveError)
import Data.Session exposing (Session)
import Data.Updater exposing (Updater, makeFieldUpdater)
import Dict exposing (Dict)
import Json.Decode exposing (Decoder)
import Json.Encode as Encode
import Service.LocalStorageService exposing (writeResourceToCurrentLocalStorage)
import Service.ModifiableRemoteResource as ModifiableRemoteResource exposing (ModifiableRemoteResource)
import Service.RemoteDataDict as RemoteDataDict
import Service.RemoteResource as RemoteResource exposing (RemoteResource)
import Service.ResourceType exposing (ResourceType)
import Update.SessionMsg exposing (SessionMsg)


createRemoteResourceInterface { getRemoteResource, setRemoteResource, encode, decoder, resourceType, toString, toKey, fromString, responseMsg } =
    let
        updateRemoteResource : Updater (RemoteResource comparable res a) -> Updater Session
        updateRemoteResource =
            makeFieldUpdater getRemoteResource setRemoteResource

        setCurrentValue : id -> Maybe res -> Updater Session
        setCurrentValue id maybeResource session =
            toKey id
                |> flip RemoteDataDict.insertValue maybeResource
                |> RemoteResource.updateActual
                |> flip updateRemoteResource session

        setExpectedValue : id -> Maybe res -> Updater Session
        setExpectedValue _ _ =
            identity

        mergeResource : id -> Maybe res -> CmdUpdater Session SessionMsg
        mergeResource =
            writeResourceToCurrentLocalStorage
                { resourceType = resourceType
                , toString = toString
                , fromString = fromString
                , encode = encode
                , decoder = decoder
                , setCurrentValue = setCurrentValue
                , setExpectedValue = setExpectedValue
                }
    in
    { resourceType = resourceType
    , toString = toString
    , fromString = fromString
    , encode = encode
    , decoder = decoder
    , setCurrentValue = setCurrentValue
    , setExpectedValue = setExpectedValue
    , getRemoteResource = getRemoteResource
    , setRemoteResource = setRemoteResource
    , updateRemoteResource = updateRemoteResource
    , resourceType = resourceType
    , decoder = decoder
    , responseMsg = responseMsg
    , toKey = toKey
    , mergeResource = mergeResource
    }


createModifiableRemoteResourceInterface :
    { a
        | getRemoteResource : Session -> ModifiableRemoteResource comparable res a
        , setRemoteResource : ModifiableRemoteResource comparable res a -> Updater Session
        , encode : res -> Encode.Value
        , decoder : Decoder res
        , resourceType : ResourceType
        , toString : id -> String
        , toKey : id -> comparable
        , fromKey : comparable -> id
        , fromString : String -> id
        , responseMsg : id -> Result GetError (Maybe res) -> SessionMsg
        , equals : res -> res -> Bool
        , gotSaveResponseMessage : res -> Maybe SaveError -> SessionMsg
        , gotDeleteResponseMessage : id -> Maybe SaveError -> SessionMsg
    }
    ->
        { getRemoteResource : Session -> ModifiableRemoteResource comparable res a
        , setRemoteResource : ModifiableRemoteResource comparable res a -> Updater Session
        , encode : res -> Encode.Value
        , decoder : Decoder res
        , resourceType : ResourceType
        , toString : id -> String
        , toKey : id -> comparable
        , fromKey : comparable -> id
        , fromString : String -> id
        , responseMsg : id -> Result GetError (Maybe res) -> SessionMsg
        , equals : res -> res -> Bool
        , gotSaveResponseMessage : res -> Maybe SaveError -> SessionMsg
        , gotDeleteResponseMessage : id -> Maybe SaveError -> SessionMsg
        , setCurrentValue : id -> Maybe res -> Updater Session
        , setExpectedValue : id -> Maybe res -> Updater Session
        , updateRemoteResource : Updater (ModifiableRemoteResource comparable res a) -> Updater Session
        , mergeResource : id -> Maybe res -> CmdUpdater Session SessionMsg
        , equals : res -> res -> Bool
        }
createModifiableRemoteResourceInterface { getRemoteResource, setRemoteResource, encode, decoder, resourceType, toString, toKey, fromKey, fromString, responseMsg, equals, gotSaveResponseMessage, gotDeleteResponseMessage } =
    let
        updateRemoteResource : Updater (ModifiableRemoteResource comparable res a) -> Updater Session
        updateRemoteResource =
            makeFieldUpdater getRemoteResource setRemoteResource

        setCurrentValue : id -> Maybe res -> Updater Session
        setCurrentValue id maybeResource session =
            toKey id
                |> flip Dict.insert maybeResource
                |> ModifiableRemoteResource.updateLocal
                |> flip updateRemoteResource session

        setExpectedValue : id -> Maybe res -> Updater Session
        setExpectedValue id maybeResource session =
            toKey id
                |> flip Dict.insert maybeResource
                |> ModifiableRemoteResource.updateExpected
                |> flip updateRemoteResource session

        mergeResource : id -> Maybe res -> CmdUpdater Session SessionMsg
        mergeResource =
            resolveConflict
                { getRemoteResource = getRemoteResource
                , toKey = toKey
                , fromKey = fromKey
                , equals = equals
                , resourceType = resourceType
                , toString = toString
                , fromString = fromString
                , encode = encode
                , decoder = decoder
                , setCurrentValue = setCurrentValue
                , setExpectedValue = setExpectedValue
                }
    in
    { resourceType = resourceType
    , toString = toString
    , fromString = fromString
    , encode = encode
    , decoder = decoder
    , setCurrentValue = setCurrentValue
    , setExpectedValue = setExpectedValue
    , getRemoteResource = getRemoteResource
    , setRemoteResource = setRemoteResource
    , updateRemoteResource = updateRemoteResource
    , resourceType = resourceType
    , decoder = decoder
    , responseMsg = responseMsg
    , toKey = toKey
    , fromKey = fromKey
    , mergeResource = mergeResource
    , equals = equals
    , gotSaveResponseMessage = gotSaveResponseMessage
    , gotDeleteResponseMessage = gotDeleteResponseMessage
    }
