module Data.HighScore exposing (HighScore, decoder, empty, encode, loadFromServer, withScore)

import Api.GCP as GCP
import Data.GetError as HttpError exposing (GetError)
import Data.LevelId as LevelId exposing (LevelId)
import Data.Score exposing (Score)
import Dict exposing (Dict)
import Extra.Decode
import Extra.Encode
import Json.Decode as Decode
import Json.Encode as Encode
import Result exposing (Result)
import Url.Builder


type alias HighScore =
    { levelId : LevelId
    , numberOfSteps : Dict Int Int
    , numberOfInstructions : Dict Int Int
    }


empty : LevelId -> HighScore
empty levelId =
    { levelId = levelId
    , numberOfSteps = Dict.empty
    , numberOfInstructions = Dict.empty
    }


withScore : Score -> HighScore -> HighScore
withScore score highScore =
    { highScore
        | numberOfSteps = Dict.update score.numberOfSteps (Maybe.withDefault 0 >> (+) 1 >> Just) highScore.numberOfSteps
        , numberOfInstructions = Dict.update score.numberOfInstructions (Maybe.withDefault 0 >> (+) 1 >> Just) highScore.numberOfInstructions
    }



-- JSON


encode : HighScore -> Encode.Value
encode highScore =
    let
        encodeDictIntInt =
            Dict.toList >> Encode.list (Extra.Encode.tuple Encode.int Encode.int)
    in
    Encode.object
        [ ( "version", Encode.int 1 )
        , ( "levelId", LevelId.encode highScore.levelId )
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

        v1 =
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
    in
    Decode.field "version" Decode.int
        |> Decode.andThen
            (\version ->
                case version of
                    1 ->
                        v1

                    _ ->
                        Decode.fail ("Unknown high score decoder version " ++ String.fromInt version)
            )



-- REST


loadFromServer : LevelId -> (Result GetError HighScore -> msg) -> Cmd msg
loadFromServer levelId toMsg =
    GCP.get
        |> GCP.withPath [ "highScores" ]
        |> GCP.withStringQueryParameter "levelId" levelId
        |> GCP.request (HttpError.expect decoder toMsg)
