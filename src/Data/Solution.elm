module Data.Solution exposing
    ( Solution
    , decoder
    , encode
    , generator
    , loadFromLocalStorage
    , loadFromServerByLevelId
    , loadFromServerBySolutionId
    , loadRemoteFromLocalStorage
    , localRemoteStorageResponse
    , localStorageResponse
    , removeRemoteFromLocalStorage
    , saveRemoteToLocalStorage
    , saveToLocalStorage
    , saveToServer
    )

import Api.GCP as GCP
import Data.AccessToken exposing (AccessToken)
import Data.Board as Board exposing (Board)
import Data.GetError as HttpError exposing (GetError)
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.SaveError as SaveError exposing (SaveError)
import Data.Score as Score exposing (Score)
import Data.SolutionBook as SolutionBook exposing (SolutionBook)
import Data.SolutionId as SolutionId exposing (SolutionId)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage
import Random
import Url.Builder


type alias Solution =
    { id : SolutionId
    , levelId : LevelId
    , score : Score
    , board : Board
    }



-- RANDOM


generator : LevelId -> Score -> Board -> Random.Generator Solution
generator levelId score board =
    Random.map
        (\id ->
            { id = id
            , levelId = levelId
            , score = score
            , board = board
            }
        )
        SolutionId.generator



-- JSON


encode : Solution -> Encode.Value
encode solution =
    Encode.object
        [ ( "version", Encode.int 1 )
        , ( "id", SolutionId.encode solution.id )
        , ( "levelId", LevelId.encode solution.levelId )
        , ( "score", Score.encode solution.score )
        , ( "board", Board.encode solution.board )
        ]


decoderV1 : Decode.Decoder Solution
decoderV1 =
    Decode.field "id" SolutionId.decoder
        |> Decode.andThen
            (\id ->
                Decode.field "levelId" LevelId.decoder
                    |> Decode.andThen
                        (\levelId ->
                            Decode.field "score" Score.decoder
                                |> Decode.andThen
                                    (\score ->
                                        Decode.field "board" Board.decoder
                                            |> Decode.andThen
                                                (\board ->
                                                    Decode.succeed
                                                        { id = id
                                                        , levelId = levelId
                                                        , score = score
                                                        , board = board
                                                        }
                                                )
                                    )
                        )
            )


decoder : Decode.Decoder Solution
decoder =
    Decode.field "version" Decode.int
        |> Decode.andThen
            (\version ->
                case version of
                    1 ->
                        decoderV1

                    _ ->
                        Decode.fail ("Unknown version: " ++ String.fromInt version)
            )



-- LOCAL STORAGE


localStorageKey : SolutionId -> String
localStorageKey solutionId =
    String.join "." [ "solutions", solutionId ]


loadFromLocalStorage : SolutionId -> Cmd msg
loadFromLocalStorage solutionId =
    Ports.LocalStorage.storageGetItem (localStorageKey solutionId)


saveToLocalStorage : Solution -> Cmd msg
saveToLocalStorage solution =
    let
        key =
            localStorageKey solution.id

        value =
            encode solution
    in
    Cmd.batch
        [ Ports.LocalStorage.storageSetItem ( key, value )
        , SolutionBook.saveToLocalStorage solution.id solution.levelId
        ]


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult LevelId Decode.Error (Maybe Solution))
localStorageResponse ( key, value ) =
    case String.split "." key of
        "solutions" :: solutionId :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> RequestResult.constructor solutionId
                |> Just

        _ ->
            Nothing


remoteKey : SolutionId -> Ports.LocalStorage.Key
remoteKey solutionId =
    String.join "."
        [ localStorageKey solutionId
        , "remote"
        ]


saveRemoteToLocalStorage : Solution -> Cmd msg
saveRemoteToLocalStorage solution =
    let
        key =
            remoteKey solution.id

        value =
            encode solution
    in
    Ports.LocalStorage.storageSetItem ( key, value )


loadRemoteFromLocalStorage : SolutionId -> Cmd msg
loadRemoteFromLocalStorage solutionId =
    let
        key =
            remoteKey solutionId
    in
    Ports.LocalStorage.storageGetItem key


removeRemoteFromLocalStorage : SolutionId -> Cmd msg
removeRemoteFromLocalStorage solutionId =
    Ports.LocalStorage.storageRemoveItem (remoteKey solutionId)


localRemoteStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult SolutionId Decode.Error (Maybe Solution))
localRemoteStorageResponse ( key, value ) =
    case String.split "." key of
        "solutions" :: solutionId :: "remote" :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> RequestResult.constructor solutionId
                |> Just

        _ ->
            Nothing



-- REST


saveToServer : (Maybe SaveError -> msg) -> AccessToken -> Solution -> Cmd msg
saveToServer toMsg accessToken solution =
    GCP.post
        |> GCP.withPath [ "solutions" ]
        |> GCP.withAccessToken accessToken
        |> GCP.withBody (encode solution)
        |> GCP.request (SaveError.expect toMsg)


loadFromServerByLevelId : (Result GetError (List Solution) -> msg) -> AccessToken -> LevelId -> Cmd msg
loadFromServerByLevelId toMsg accessToken levelId =
    GCP.get
        |> GCP.withPath [ "solutions" ]
        |> GCP.withQueryParameters [ Url.Builder.string "levelId" levelId ]
        |> GCP.withAccessToken accessToken
        |> GCP.request (HttpError.expect (Decode.list decoder) toMsg)


loadFromServerBySolutionId : (Result GetError (Maybe Solution) -> msg) -> AccessToken -> SolutionId -> Cmd msg
loadFromServerBySolutionId toMsg accessToken solutionId =
    GCP.get
        |> GCP.withPath [ "solutions" ]
        |> GCP.withQueryParameters [ Url.Builder.string "solutionId" solutionId ]
        |> GCP.withAccessToken accessToken
        |> GCP.request (HttpError.expectMaybe decoder toMsg)
