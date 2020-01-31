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
import Data.DraftId as DraftId exposing (DraftId)
import Data.GetError as HttpError exposing (GetError)
import Data.History as History exposing (History)
import Data.Instruction as Instruction
import Data.Level exposing (Level)
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.SaveError as SaveError exposing (SaveError)
import Json.Decode as Decode
import Json.Encode as Encode
import Json.Encode.Extra
import Ports.LocalStorage as LocalStorage
import Random


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
        [ ( "version", Encode.int 1 )
        , ( "id", DraftId.encode draft.id )
        , ( "levelId", LevelId.encode draft.levelId )
        , ( "board", Board.encode (History.current draft.boardHistory) )
        ]


decoder : Decode.Decoder Draft
decoder =
    let
        v1 =
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
    in
    Decode.field "version" Decode.int
        |> Decode.andThen
            (\version ->
                case version of
                    1 ->
                        v1

                    _ ->
                        Decode.fail ("Unknown draft decoder version " ++ String.fromInt version)
            )



-- LOCAL STORAGE


localStorageKey : DraftId -> LocalStorage.Key
localStorageKey draftId =
    String.join "."
        [ "drafts"
        , DraftId.toString draftId
        ]


saveToLocalStorage : DraftId -> Maybe Draft -> Cmd msg
saveToLocalStorage draftId maybeDraft =
    LocalStorage.storageSetItem
        ( localStorageKey draftId
        , Json.Encode.Extra.maybe encode maybeDraft
        )


loadFromLocalStorage : DraftId -> Cmd msg
loadFromLocalStorage draftId =
    let
        key =
            localStorageKey draftId
    in
    LocalStorage.storageGetItem key


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


remoteKey : DraftId -> LocalStorage.Key
remoteKey draftId =
    String.join "."
        [ localStorageKey draftId
        , "remote"
        ]


saveRemoteToLocalStorage : DraftId -> Maybe Draft -> Cmd msg
saveRemoteToLocalStorage draftId maybeDraft =
    LocalStorage.storageSetItem
        ( remoteKey draftId
        , Json.Encode.Extra.maybe encode maybeDraft
        )


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


removeRemoteFromLocalStorage : DraftId -> Cmd msg
removeRemoteFromLocalStorage draftId =
    LocalStorage.storageRemoveItem (remoteKey draftId)


removeFromLocalStorage : DraftId -> Cmd msg
removeFromLocalStorage draftId =
    LocalStorage.storageRemoveItem (localStorageKey draftId)



-- REST


loadAllFromServer : (Result GetError (List Draft) -> msg) -> AccessToken -> Cmd msg
loadAllFromServer toMsg accessToken =
    GCP.get
        |> GCP.withPath [ "drafts" ]
        |> GCP.withAccessToken accessToken
        |> GCP.request (HttpError.expect (Decode.list decoder) toMsg)


loadFromServer : (DraftId -> Result GetError (Maybe Draft) -> msg) -> DraftId -> AccessToken -> Cmd msg
loadFromServer toMsg draftId accessToken =
    GCP.get
        |> GCP.withPath [ "drafts" ]
        |> GCP.withStringQueryParameter "draftId" draftId
        |> GCP.withAccessToken accessToken
        |> GCP.request (HttpError.expectMaybe decoder (toMsg draftId))


loadFromServerByLevelId : (Result GetError (List Draft) -> msg) -> AccessToken -> LevelId -> Cmd msg
loadFromServerByLevelId toMsg accessToken levelId =
    GCP.get
        |> GCP.withPath [ "drafts" ]
        |> GCP.withStringQueryParameter "levelId" levelId
        |> GCP.withAccessToken accessToken
        |> GCP.request (HttpError.expect (Decode.list decoder) toMsg)


saveToServer : (Maybe SaveError -> msg) -> AccessToken -> Draft -> Cmd msg
saveToServer toMsg accessToken draft =
    GCP.put
        |> GCP.withPath [ "drafts" ]
        |> GCP.withAccessToken accessToken
        |> GCP.withBody (encode draft)
        |> GCP.request (SaveError.expect toMsg)


deleteFromServer : (DraftId -> Maybe SaveError -> msg) -> DraftId -> AccessToken -> Cmd msg
deleteFromServer toMsg draftId accessToken =
    GCP.delete
        |> GCP.withPath [ "drafts" ]
        |> GCP.withStringQueryParameter "draftId" draftId
        |> GCP.withAccessToken accessToken
        |> GCP.request (SaveError.expect (toMsg draftId))
