module Data.DraftBook exposing (DraftBook, decoder, empty, encode, loadFromLocalStorage, localStorageResponse, saveToLocalStorage, withDraftId, withDraftIds)

import Basics.Extra exposing (flip)
import Data.DraftId as DraftId exposing (DraftId)
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Extra.Decode
import Extra.Encode
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
withDraftId draftId levelDrafts =
    { levelDrafts
        | draftIds = Set.insert draftId levelDrafts.draftIds
    }


withDraftIds : Set DraftId -> DraftBook -> DraftBook
withDraftIds draftIds levelDrafts =
    { levelDrafts
        | draftIds = Set.union levelDrafts.draftIds draftIds
    }



-- JSON


encode : DraftBook -> Encode.Value
encode levelDrafts =
    Encode.object
        [ ( "levelId", LevelId.encode levelDrafts.levelId )
        , ( "draftIds", Extra.Encode.set DraftId.encode levelDrafts.draftIds )
        ]


decoder : Decode.Decoder DraftBook
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
