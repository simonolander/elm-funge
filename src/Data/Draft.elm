module Data.Draft exposing (Draft, decoder, encode, generator, getInstructionCount, loadFromLocalStorage, localStorageResponse, pushBoard, redo, saveToLocalStorage, undo, withScore)

import Data.Board as Board exposing (Board)
import Data.DraftBook as DraftBook
import Data.DraftId as DraftId exposing (DraftId)
import Data.History as History exposing (History)
import Data.Instruction as Instruction
import Data.Level exposing (Level)
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.Score as Score exposing (Score)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage
import Random


type alias Draft =
    { id : DraftId
    , boardHistory : History Board
    , maybeScore : Maybe Score
    , levelId : LevelId
    }


pushBoard : Board -> Draft -> Draft
pushBoard board draft =
    { draft
        | boardHistory = History.push board draft.boardHistory
        , maybeScore = Nothing
    }


withScore : Score -> Draft -> Draft
withScore score draft =
    { draft
        | maybeScore = Just score
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
    DraftId.generate
        |> Random.map
            (\id ->
                { id = id
                , boardHistory = History.singleton level.initialBoard
                , maybeScore = Nothing
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
        , ( "maybeScore"
          , draft.maybeScore
                |> Maybe.map Score.encode
                |> Maybe.withDefault Encode.null
          )
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
                                        Decode.field "maybeScore" (Decode.nullable Score.decoder)
                                            |> Decode.andThen
                                                (\maybeScore ->
                                                    Decode.succeed
                                                        { id = id
                                                        , boardHistory = History.singleton board
                                                        , maybeScore = maybeScore
                                                        , levelId = levelId
                                                        }
                                                )
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
