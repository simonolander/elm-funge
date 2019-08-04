module Data.Draft exposing
    ( Draft
    , decoder
    , deleteFromServer
    , encode
    , eq
    , generator
    , getInstructionCount
    , loadAllFromServer
    , loadFromLocalStorage
    , loadFromServer
    , loadFromServerByLevelId
    , loadRemoteFromLocalStorage
    , localRemoteStorageResponse
    , localStorageResponse
    , pushBoard
    , redo
    , removeFromLocalStorage
    , removeRemoteFromLocalStorage
    , saveRemoteToLocalStorage
    , saveToLocalStorage
    , saveToServer
    , undo
    )

import Api.GCP as GCP
import Data.AccessToken exposing (AccessToken)
import Data.Board as Board exposing (Board)
import Data.DetailedHttpError exposing (DetailedHttpError)
import Data.DraftBook as DraftBook
import Data.DraftId as DraftId exposing (DraftId)
import Data.History as History exposing (History)
import Data.Instruction as Instruction
import Data.Level exposing (Level)
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage
import Random
import Url.Builder


type alias Draft =
    { id : DraftId
    , boardHistory : History Board
    , levelId : LevelId
    }


eq : Draft -> Draft -> Bool
eq draft1 draft2 =
    draft1.id == draft2.id && draft1.levelId == draft2.levelId && History.current draft1.boardHistory == History.current draft2.boardHistory


pushBoard : Board -> Draft -> Draft
pushBoard board draft =
    { draft
        | boardHistory = History.push board draft.boardHistory
    }


undo : Draft -> Draft
undo draft =
    { draft
        | boardHistory = History.back draft.boardHistory
    }


redo : Draft -> Draft
redo draft =
    { draft
        | boardHistory = History.forward draft.boardHistory
    }


getInstructionCount : Board -> Draft -> Int
getInstructionCount initialBoard draft =
    let
        count =
            Board.count ((/=) Instruction.NoOp)

        initialInstructionCount =
            count initialBoard

        currentInstructionCount =
            History.current draft.boardHistory
                |> count
    in
    currentInstructionCount - initialInstructionCount



-- RANDOM


generator : Level -> Random.Generator Draft
generator level =
    DraftId.generator
        |> Random.map
            (\id ->
                { id = id
                , boardHistory = History.singleton level.initialBoard
                , levelId = level.id
                }
            )



-- JSON


encode : Draft -> Encode.Value
encode draft =
    Encode.object
        [ ( "id", DraftId.encode draft.id )
        , ( "levelId", LevelId.encode draft.levelId )
        , ( "board", Board.encode (History.current draft.boardHistory) )
        ]


decoder : Decode.Decoder Draft
decoder =
    Decode.field "id" DraftId.decoder
        |> Decode.andThen
            (\id ->
                Decode.field "levelId" LevelId.decoder
                    |> Decode.andThen
                        (\levelId ->
                            Decode.field "board" Board.decoder
                                |> Decode.andThen
                                    (\board ->
                                        Decode.succeed
                                            { id = id
                                            , boardHistory = History.singleton board
                                            , levelId = levelId
                                            }
                                    )
                        )
            )



-- LOCAL STORAGE


localStorageKey : DraftId -> Ports.LocalStorage.Key
localStorageKey draftId =
    String.join "."
        [ "drafts"
        , DraftId.toString draftId
        ]


saveToLocalStorage : Draft -> Cmd msg
saveToLocalStorage draft =
    let
        key =
            localStorageKey draft.id

        value =
            encode draft
    in
    Cmd.batch
        [ Ports.LocalStorage.storageSetItem ( key, value )
        , DraftBook.saveToLocalStorage draft.id draft.levelId
        ]


loadFromLocalStorage : DraftId -> Cmd msg
loadFromLocalStorage draftId =
    let
        key =
            localStorageKey draftId
    in
    Ports.LocalStorage.storageGetItem key


removeFromLocalStorage : DraftId -> Cmd msg
removeFromLocalStorage draftId =
    Ports.LocalStorage.storageRemoveItem (localStorageKey draftId)


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult DraftId Decode.Error (Maybe Draft))
localStorageResponse ( key, value ) =
    case String.split "." key of
        "drafts" :: draftId :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> RequestResult.constructor draftId
                |> Just

        _ ->
            Nothing


remoteKey : DraftId -> Ports.LocalStorage.Key
remoteKey draftId =
    String.join "."
        [ localStorageKey draftId
        , "remote"
        ]


saveRemoteToLocalStorage : Draft -> Cmd msg
saveRemoteToLocalStorage draft =
    let
        key =
            remoteKey draft.id

        value =
            encode draft
    in
    Cmd.batch
        [ Ports.LocalStorage.storageSetItem ( key, value )
        , DraftBook.saveToLocalStorage draft.id draft.levelId
        ]


loadRemoteFromLocalStorage : DraftId -> Cmd msg
loadRemoteFromLocalStorage draftId =
    let
        key =
            remoteKey draftId
    in
    Ports.LocalStorage.storageGetItem key


removeRemoteFromLocalStorage : DraftId -> Cmd msg
removeRemoteFromLocalStorage draftId =
    Ports.LocalStorage.storageRemoveItem (remoteKey draftId)


localRemoteStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult DraftId Decode.Error (Maybe Draft))
localRemoteStorageResponse ( key, value ) =
    case String.split "." key of
        "drafts" :: draftId :: "remote" :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> RequestResult.constructor draftId
                |> Just

        _ ->
            Nothing



-- REST


loadAllFromServer : AccessToken -> (Result DetailedHttpError (List Draft) -> msg) -> Cmd msg
loadAllFromServer accessToken toMsg =
    GCP.get (Decode.list decoder)
        |> GCP.withPath [ "drafts" ]
        |> GCP.withAccessToken accessToken
        |> GCP.request toMsg


loadFromServer : AccessToken -> (RequestResult DraftId DetailedHttpError Draft -> msg) -> DraftId -> Cmd msg
loadFromServer accessToken toMsg draftId =
    GCP.get decoder
        |> GCP.withPath [ "drafts" ]
        |> GCP.withQueryParameters [ Url.Builder.string "draftId" draftId ]
        |> GCP.withAccessToken accessToken
        |> GCP.request (RequestResult.constructor draftId >> toMsg)


loadFromServerByLevelId : AccessToken -> (RequestResult LevelId DetailedHttpError (List Draft) -> msg) -> LevelId -> Cmd msg
loadFromServerByLevelId accessToken toMsg levelId =
    GCP.get (Decode.list decoder)
        |> GCP.withPath [ "drafts" ]
        |> GCP.withQueryParameters [ Url.Builder.string "levelId" levelId ]
        |> GCP.withAccessToken accessToken
        |> GCP.request (RequestResult.constructor levelId >> toMsg)


saveToServer : AccessToken -> (RequestResult Draft DetailedHttpError () -> msg) -> Draft -> Cmd msg
saveToServer accessToken toMsg draft =
    GCP.put (Decode.succeed ())
        |> GCP.withPath [ "drafts" ]
        |> GCP.withAccessToken accessToken
        |> GCP.withBody (encode draft)
        |> GCP.request (RequestResult.constructor draft >> toMsg)


deleteFromServer : (RequestResult DraftId DetailedHttpError () -> msg) -> AccessToken -> DraftId -> Cmd msg
deleteFromServer toMsg accessToken draftId =
    GCP.delete (Decode.succeed ())
        |> GCP.withPath [ "drafts" ]
        |> GCP.withQueryParameters [ Url.Builder.string "draftId" draftId ]
        |> GCP.withAccessToken accessToken
        |> GCP.request (RequestResult.constructor draftId >> toMsg)
