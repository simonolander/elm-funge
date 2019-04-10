module Data.Draft exposing (Draft, decoder, encode, fromKey, generator, getDraftsFromLocalStorage, loadFromLocalStorage, loadedFromLocalStorage, pushBoard, redo, saveToLocalStorage, undo, withScore)

import Data.Board as Board exposing (Board)
import Data.DraftId as DraftId exposing (DraftId)
import Data.History as History exposing (History)
import Data.Level exposing (Level)
import Data.LevelId as LevelId exposing (LevelId)
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
        , ( "LevelId", LevelId.encode draft.levelId )
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
                                        Decode.field "score" (Decode.nullable Score.decoder)
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


toKey : DraftId -> Ports.LocalStorage.Key
toKey draftId =
    String.join "."
        [ "drafts"
        , DraftId.toString draftId
        ]


fromKey : Ports.LocalStorage.Key -> Maybe DraftId
fromKey key =
    case String.split "." key of
        "drafts" :: draftId :: [] ->
            Just (DraftId.DraftId draftId)

        _ ->
            Nothing


saveToLocalStorage : Draft -> Cmd msg
saveToLocalStorage draft =
    let
        key =
            toKey draft.id

        value =
            encode draft
                |> Encode.encode 0
    in
    Ports.LocalStorage.storageSetItem ( key, value )


loadFromLocalStorage : DraftId -> Cmd msg
loadFromLocalStorage draftId =
    let
        key =
            toKey draftId
    in
    Ports.LocalStorage.storageGetItem key


loadedFromLocalStorage : ( Ports.LocalStorage.Key, Ports.LocalStorage.Value ) -> Result String (Maybe Draft)
loadedFromLocalStorage ( key, value ) =
    case fromKey key of
        Just (DraftId.DraftId draftId) ->
            case Decode.decodeString (Decode.nullable decoder) value of
                Ok (Just draft) ->
                    if DraftId.toString draft.id == draftId then
                        Ok (Just draft)

                    else
                        Err ("Draft ids doesn't match, expected " ++ draftId ++ " but was " ++ DraftId.toString draft.id)

                Ok Nothing ->
                    Ok Nothing

                Err error ->
                    Err (Decode.errorToString error)

        Nothing ->
            Err ("Malformed key: " ++ key)


getDraftsFromLocalStorage : Ports.LocalStorage.Key -> List LevelId -> Cmd msg
getDraftsFromLocalStorage tag levelIds =
    let
        toDraftsKey levelId =
            String.join "." [ "levels", levelId, "draftIds" ]
    in
    Ports.LocalStorage.storageGetAndThen
        ( tag
        , levelIds
            |> List.map toDraftsKey
        , [ { prefix = Nothing
            , concat = True
            }
          , { prefix = Just "drafts"
            , concat = False
            }
          ]
        )
