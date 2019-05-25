module Data.HighScore exposing (HighScore, decoder, encode, loadFromServer)

import Api.GCP as GCP
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Dict exposing (Dict)
import Extra.Decode
import Extra.Encode
import Json.Decode as Decode
import Json.Encode as Encode
import Url.Builder


type alias HighScore =
    { levelId : LevelId
    , numberOfSteps : Dict Int Int
    , numberOfInstructions : Dict Int Int
    }



-- JSON


encode : HighScore -> Encode.Value
encode highScore =
    let
        encodeDictIntInt =
            Dict.toList >> Encode.list (Extra.Encode.tuple Encode.int Encode.int)
    in
    Encode.object
        [ ( "levelId", LevelId.encode highScore.levelId )
        , ( "numberOfSteps", encodeDictIntInt highScore.numberOfSteps )
        , ( "numberOfInstructions", encodeDictIntInt highScore.numberOfInstructions )
        ]


decoder : Decode.Decoder HighScore
decoder =
    let
        intIntDictDecoder =
            Extra.Decode.tuple Decode.int Decode.int
                |> Decode.list
                |> Decode.map Dict.fromList
    in
    Decode.field "numberOfSteps" intIntDictDecoder
        |> Decode.andThen
            (\numberOfSteps ->
                Decode.field "numberOfInstructions" intIntDictDecoder
                    |> Decode.andThen
                        (\numberOfInstructions ->
                            Decode.field "levelId" LevelId.decoder
                                |> Decode.andThen
                                    (\levelId ->
                                        Decode.succeed
                                            { levelId = levelId
                                            , numberOfSteps = numberOfSteps
                                            , numberOfInstructions = numberOfInstructions
                                            }
                                    )
                        )
            )



-- REST


loadFromServer : LevelId -> (RequestResult LevelId HighScore -> msg) -> Cmd msg
loadFromServer levelId toMsg =
    let
        path =
            [ "highScores" ]

        query =
            [ Url.Builder.string "levelId" levelId ]
    in
    GCP.get path query decoder (RequestResult.constructor levelId >> toMsg)
