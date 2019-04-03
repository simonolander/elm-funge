module Data.Draft exposing (Draft, decoder, encode, pushBoard, redo, undo, withScore)

import Data.Board as Board exposing (Board)
import Data.DraftId as DraftId exposing (DraftId)
import Data.History as History exposing (History)
import Data.Score as Score exposing (Score)
import Json.Decode as Decode
import Json.Encode as Encode


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
