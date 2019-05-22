module Data.LevelDrafts exposing (LevelDrafts, decoder, empty, encode, loadFromLocalStorage, localStorageResponse, saveToLocalStorage, withDraftId)

import Data.DraftId as DraftId exposing (DraftId)
import Data.LevelId as LevelId exposing (LevelId)
import Extra.Decode
import Extra.Encode
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage
import Set exposing (Set)


type alias LevelDrafts =
    { levelId : LevelId
    , draftIds : Set DraftId
    }


empty : LevelId -> LevelDrafts
empty levelId =
    { levelId = levelId
    , draftIds = Set.empty
    }


withDraftId : DraftId -> LevelDrafts -> LevelDrafts
withDraftId draftId levelDrafts =
    { levelDrafts
        | draftIds = Set.insert draftId levelDrafts.draftIds
    }



-- JSON


encode : LevelDrafts -> Encode.Value
encode levelDrafts =
    Encode.object
        [ ( "levelId", LevelId.encode levelDrafts.levelId )
        , ( "draftIds", Extra.Encode.set DraftId.encode levelDrafts.draftIds )
        ]


decoder : Decode.Decoder LevelDrafts
decoder =
    Decode.field "levelId" LevelId.decoder
        |> Decode.andThen
            (\levelId ->
                Decode.field "draftIds" (Extra.Decode.set DraftId.decoder)
                    |> Decode.andThen
                        (\draftIds ->
                            Decode.succeed
                                { levelId = levelId
                                , draftIds = draftIds
                                }
                        )
            )



-- LOCAL STORAGE


localStorageKey : LevelId -> Ports.LocalStorage.Key
localStorageKey levelId =
    String.join "." [ "levels", levelId, "draftIds" ]


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


localStorageResponse : (Result Decode.Error (Maybe LevelDrafts) -> a) -> ( String, Encode.Value ) -> Maybe a
localStorageResponse onResult ( key, value ) =
    case String.split "." key of
        "levels" :: _ :: "draftIds" :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> onResult
                |> Just

        _ ->
            Nothing
