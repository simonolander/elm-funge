module Data.DraftBook exposing (DraftBook, empty, loadFromLocalStorage, localStorageResponse, removeDraftIdFromLocalStorage, removeFromLocalStorage, saveToLocalStorage, withDraftId, withDraftIds, withoutDraftId)

import Basics.Extra exposing (flip)
import Data.DraftId as DraftId exposing (DraftId)
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Extra.Decode
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage
import Set exposing (Set)


type alias DraftBook =
    { levelId : LevelId
    , draftIds : Set DraftId
    }


empty : LevelId -> DraftBook
empty levelId =
    { levelId = levelId
    , draftIds = Set.empty
    }


withDraftId : DraftId -> DraftBook -> DraftBook
withDraftId draftId draftBook =
    { draftBook
        | draftIds = Set.insert draftId draftBook.draftIds
    }


withDraftIds : Set DraftId -> DraftBook -> DraftBook
withDraftIds draftIds draftBook =
    { draftBook
        | draftIds = Set.union draftBook.draftIds draftIds
    }


withoutDraftId : DraftId -> DraftBook -> DraftBook
withoutDraftId draftId draftBook =
    { draftBook | draftIds = Set.remove draftId draftBook.draftIds }



-- LOCAL STORAGE


localStorageKey : LevelId -> Ports.LocalStorage.Key
localStorageKey levelId =
    String.join "." [ "levels", levelId, "draftBook" ]


saveToLocalStorage : DraftId -> LevelId -> Cmd msg
saveToLocalStorage draftId levelId =
    let
        key =
            localStorageKey levelId

        value =
            DraftId.encode draftId
    in
    Ports.LocalStorage.storagePushToSet ( key, value )


loadFromLocalStorage : LevelId -> Cmd msg
loadFromLocalStorage levelId =
    let
        key =
            localStorageKey levelId
    in
    Ports.LocalStorage.storageGetItem key


removeFromLocalStorage : LevelId -> Cmd msg
removeFromLocalStorage levelId =
    Ports.LocalStorage.storageRemoveItem (localStorageKey levelId)


removeDraftIdFromLocalStorage : LevelId -> DraftId -> Cmd msg
removeDraftIdFromLocalStorage levelId draftId =
    Ports.LocalStorage.storageRemoveFromSet ( localStorageKey levelId, DraftId.encode draftId )


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult LevelId Decode.Error DraftBook)
localStorageResponse ( key, value ) =
    case String.split "." key of
        "levels" :: levelId :: "draftBook" :: [] ->
            let
                localStorageDecoder =
                    DraftId.decoder
                        |> Extra.Decode.set
                        |> Decode.map (flip withDraftIds (empty levelId))
                        |> Decode.nullable
                        |> Decode.map (Maybe.withDefault (empty levelId))
            in
            value
                |> Decode.decodeValue localStorageDecoder
                |> RequestResult.constructor levelId
                |> Just

        _ ->
            Nothing
