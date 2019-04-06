module Data.Draft exposing (Draft, decoder, encode, fromKey, loadFromLocalStorage, loadedFromLocalStorage, pushBoard, redo, saveToLocalStorage, undo, withScore)

import Data.Board as Board exposing (Board)
import Data.DraftId as DraftId exposing (DraftId)
import Data.History as History exposing (History)
import Data.Score as Score exposing (Score)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage


type alias Draft =
    { id : DraftId
    , boardHistory : History Board
    , maybeScore : Maybe Score
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



-- JSON


encode : Draft -> Encode.Value
encode draft =
    Encode.object
        [ ( "id", DraftId.encode draft.id )
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
                                            }
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
