module Data.Blueprint exposing
    ( Blueprint
    , decoder
    , deleteFromServer
    , encode
    , generator
    , loadAllFromServer
    , loadFromLocalStorage
    , loadFromServerByBlueprintId
    , loadFromServerByBlueprintIds
    , localRemoteStorageResponse
    , localStorageResponse
    , removeFromLocalStorage
    , removeRemoteFromLocalStorage
    , saveRemoteToLocalStorage
    , saveToLocalStorage
    , saveToServer
    )

import Api.GCP as GCP
import Array exposing (Array)
import Data.AccessToken exposing (AccessToken)
import Data.BlueprintId as BlueprintId exposing (BlueprintId)
import Data.Board as Board exposing (Board)
import Data.GetError as GetError exposing (GetError)
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool exposing (InstructionTool(..))
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.SaveError as SaveError exposing (SaveError)
import Data.Suite exposing (Suite)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage as LocalStorage
import Random


type alias Blueprint =
    { id : BlueprintId
    , name : String
    , description : List String
    , suites : List Suite
    , initialBoard : Board
    , instructionTools : Array InstructionTool
    }



-- RANDOM


generator : Random.Generator Blueprint
generator =
    Random.map
        (\levelId ->
            { id = levelId
            , name = "New level"
            , description = [ "Enter a description" ]
            , suites =
                [ { input = []
                  , output = []
                  }
                ]
            , initialBoard = Board.empty 4 4
            , instructionTools =
                JustInstruction NoOp
                    |> List.singleton
                    |> Array.fromList
            }
        )
        BlueprintId.generator



-- JSON


encode : Blueprint -> Encode.Value
encode blueprint =
    Encode.object
        [ ( "version", Encode.int 1 )
        , ( "id", BlueprintId.encode blueprint.id )
        , ( "name", Encode.string blueprint.name )
        , ( "description", Encode.list Encode.string blueprint.description )
        , ( "suites", Encode.list Data.Suite.encode blueprint.suites )
        , ( "initialBoard", Data.Board.encode blueprint.initialBoard )
        , ( "instructionTools", Encode.array Data.InstructionTool.encode blueprint.instructionTools )
        ]


decoder : Decode.Decoder Blueprint
decoder =
    let
        v1 =
            Decode.field "id" BlueprintId.decoder
                |> Decode.andThen
                    (\id ->
                        Decode.field "name" Decode.string
                            |> Decode.andThen
                                (\name ->
                                    Decode.field "description" (Decode.list Decode.string)
                                        |> Decode.andThen
                                            (\description ->
                                                Decode.field "suites" (Decode.list Data.Suite.decoder)
                                                    |> Decode.andThen
                                                        (\suites ->
                                                            Decode.field "initialBoard" Data.Board.decoder
                                                                |> Decode.andThen
                                                                    (\initialBoard ->
                                                                        Decode.field "instructionTools" (Decode.array Data.InstructionTool.decoder)
                                                                            |> Decode.andThen
                                                                                (\instructionTools ->
                                                                                    Decode.succeed
                                                                                        { id = id
                                                                                        , name = name
                                                                                        , description = description
                                                                                        , suites = suites
                                                                                        , initialBoard = initialBoard
                                                                                        , instructionTools = instructionTools
                                                                                        }
                                                                                )
                                                                    )
                                                        )
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
                        Decode.fail ("Unknown blueprint version: " ++ String.fromInt version)
            )



-- REST


path : List String
path =
    [ "blueprints" ]


loadAllFromServer : (Result GetError (List Blueprint) -> msg) -> AccessToken -> Cmd msg
loadAllFromServer toMsg accessToken =
    GCP.get
        |> GCP.withPath path
        |> GCP.withAccessToken accessToken
        |> GCP.request (GetError.expect (Decode.list decoder) toMsg)


loadFromServerByBlueprintIds : (List BlueprintId -> Result GetError (List Blueprint) -> msg) -> AccessToken -> List BlueprintId -> Cmd msg
loadFromServerByBlueprintIds toMsg accessToken blueprintIds =
    GCP.get
        |> GCP.withPath path
        |> GCP.withAccessToken accessToken
        |> GCP.withStringListQueryParameter "blueprintIds" blueprintIds
        |> GCP.request (GetError.expect (Decode.list decoder) (toMsg blueprintIds))


loadFromServerByBlueprintId : (BlueprintId -> Result GetError (Maybe Blueprint) -> msg) -> AccessToken -> String -> Cmd msg
loadFromServerByBlueprintId toMsg accessToken blueprintId =
    GCP.get
        |> GCP.withPath path
        |> GCP.withAccessToken accessToken
        |> GCP.withStringQueryParameter "blueprintId" blueprintId
        |> GCP.request (GetError.expectMaybe decoder (toMsg blueprintId))


saveToServer : (Blueprint -> Maybe SaveError -> msg) -> Blueprint -> AccessToken -> Cmd msg
saveToServer toMsg blueprint accessToken =
    GCP.put
        |> GCP.withPath path
        |> GCP.withAccessToken accessToken
        |> GCP.withBody (encode blueprint)
        |> GCP.request (SaveError.expect (toMsg blueprint))


deleteFromServer : (BlueprintId -> Maybe SaveError -> msg) -> AccessToken -> BlueprintId -> Cmd msg
deleteFromServer toMsg accessToken blueprintId =
    GCP.delete
        |> GCP.withPath [ "blueprints" ]
        |> GCP.withStringQueryParameter "blueprintId" blueprintId
        |> GCP.withAccessToken accessToken
        |> GCP.request (SaveError.expect (toMsg blueprintId))



-- LOCAL STORAGE


localStorageKey : BlueprintId -> String
localStorageKey blueprintId =
    String.join "." [ "blueprints", blueprintId ]


remoteKey : BlueprintId -> String
remoteKey blueprintId =
    String.join "." [ localStorageKey blueprintId, "remote" ]


saveToLocalStorage : Blueprint -> Cmd msg
saveToLocalStorage blueprint =
    LocalStorage.storageSetItem
        ( localStorageKey blueprint.id
        , encode blueprint
        )


loadFromLocalStorage : BlueprintId -> Cmd msg
loadFromLocalStorage blueprintId =
    LocalStorage.storageGetItem (localStorageKey blueprintId)


saveRemoteToLocalStorage : Blueprint -> Cmd msg
saveRemoteToLocalStorage blueprint =
    LocalStorage.storageSetItem
        ( remoteKey blueprint.id
        , encode blueprint
        )


removeFromLocalStorage : BlueprintId -> Cmd msg
removeFromLocalStorage blueprintId =
    LocalStorage.storageRemoveItem (localStorageKey blueprintId)


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult BlueprintId Decode.Error (Maybe Blueprint))
localStorageResponse ( key, value ) =
    case String.split "." key of
        "blueprints" :: blueprintId :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> RequestResult.constructor blueprintId
                |> Just

        _ ->
            Nothing


removeRemoteFromLocalStorage : BlueprintId -> Cmd msg
removeRemoteFromLocalStorage blueprintId =
    LocalStorage.storageRemoveItem (remoteKey blueprintId)


localRemoteStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult BlueprintId Decode.Error (Maybe Blueprint))
localRemoteStorageResponse ( key, value ) =
    case String.split "." key of
        "blueprints" :: blueprintId :: "remote" :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> RequestResult.constructor blueprintId
                |> Just

        _ ->
            Nothing
