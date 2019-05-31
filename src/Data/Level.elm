module Data.Level exposing (Level, constraints, decoder, encode, generator, loadFromLocalStorage, localStorageKey, localStorageResponse, removeFromLocalStorage, saveToLocalStorage, withDescription, withIO, withInitialBoard, withInstructionTool, withInstructionTools, withName)

import Array exposing (Array)
import Data.Board as Board exposing (Board)
import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.IO as IO exposing (IO)
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool as InstructionTool exposing (InstructionTool(..))
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage as LocalStorage
import Random


type alias Level =
    { id : LevelId
    , index : Int
    , campaignId : CampaignId
    , name : String
    , description : List String
    , io : IO
    , initialBoard : Board
    , instructionTools : Array InstructionTool
    }


constraints =
    { minWidth = 1
    , maxWidth = 31
    , minHeight = 1
    , maxHeight = 31
    }


withInstructionTool : Int -> InstructionTool -> Level -> Level
withInstructionTool index instructionTool level =
    { level
        | instructionTools =
            Array.set
                index
                instructionTool
                level.instructionTools
    }


withName : String -> Level -> Level
withName name level =
    { level | name = name }


withDescription : List String -> Level -> Level
withDescription description level =
    { level | description = description }


withIO : IO -> Level -> Level
withIO io level =
    { level | io = io }


withInitialBoard : Board -> Level -> Level
withInitialBoard initialBoard level =
    { level | initialBoard = initialBoard }


withInstructionTools : Array InstructionTool -> Level -> Level
withInstructionTools instructionTools level =
    { level | instructionTools = instructionTools }



-- LOCAL STORAGE


localStorageKey : LevelId -> LocalStorage.Key
localStorageKey levelId =
    String.join "." [ "levels", levelId ]


loadFromLocalStorage : LevelId -> Cmd msg
loadFromLocalStorage levelId =
    LocalStorage.storageGetItem (localStorageKey levelId)


saveToLocalStorage : Level -> Cmd msg
saveToLocalStorage level =
    LocalStorage.storageSetItem
        ( localStorageKey level.id
        , encode level
        )


removeFromLocalStorage : LevelId -> Cmd msg
removeFromLocalStorage levelId =
    LocalStorage.storageRemoveItem (localStorageKey levelId)


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult LevelId Decode.Error (Maybe Level))
localStorageResponse ( key, value ) =
    case String.split "." key of
        "levels" :: levelId :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> RequestResult.constructor levelId
                |> Just

        _ ->
            Nothing



-- RANDOM


generator : Random.Generator Level
generator =
    Random.map
        (\levelId ->
            { id = levelId
            , index = 0
            , campaignId = CampaignId.blueprints
            , name = "New level"
            , description = [ "Enter a description" ]
            , io =
                { input = []
                , output = []
                }
            , initialBoard = Board.empty 4 4
            , instructionTools =
                JustInstruction NoOp
                    |> List.singleton
                    |> Array.fromList
            }
        )
        LevelId.generator



-- JSON


encode : Level -> Encode.Value
encode level =
    Encode.object
        [ ( "version", Encode.int 1 )
        , ( "id", Encode.string level.id )
        , ( "index", Encode.int level.index )
        , ( "campaignId", CampaignId.encode level.campaignId )
        , ( "name", Encode.string level.name )
        , ( "description", Encode.list Encode.string level.description )
        , ( "io", IO.encode level.io )
        , ( "initialBoard", Board.encode level.initialBoard )
        , ( "instructionTools", Encode.array InstructionTool.encode level.instructionTools )
        ]


decoder : Decode.Decoder Level
decoder =
    let
        levelDecoderV1 =
            Decode.field "id" Decode.string
                |> Decode.andThen
                    (\id ->
                        Decode.field "index" Decode.int
                            |> Decode.andThen
                                (\index ->
                                    Decode.field "campaignId" CampaignId.decoder
                                        |> Decode.andThen
                                            (\campaignId ->
                                                Decode.field "name" Decode.string
                                                    |> Decode.andThen
                                                        (\name ->
                                                            Decode.field "description" (Decode.list Decode.string)
                                                                |> Decode.andThen
                                                                    (\description ->
                                                                        Decode.field "io" IO.decoder
                                                                            |> Decode.andThen
                                                                                (\io ->
                                                                                    Decode.field "initialBoard" Board.decoder
                                                                                        |> Decode.andThen
                                                                                            (\initialBoard ->
                                                                                                Decode.field "instructionTools" (Decode.array InstructionTool.decoder)
                                                                                                    |> Decode.andThen
                                                                                                        (\instructionTools ->
                                                                                                            Decode.succeed
                                                                                                                { id = id
                                                                                                                , name = name
                                                                                                                , index = index
                                                                                                                , campaignId = campaignId
                                                                                                                , description = description
                                                                                                                , io = io
                                                                                                                , initialBoard = initialBoard
                                                                                                                , instructionTools = instructionTools
                                                                                                                }
                                                                                                        )
                                                                                            )
                                                                                )
                                                                    )
                                                        )
                                            )
                                )
                    )

        levelDecoderV2 =
            Decode.field "id" Decode.string
                |> Decode.andThen
                    (\id ->
                        Decode.field "index" Decode.int
                            |> Decode.andThen
                                (\index ->
                                    Decode.field "campaignId" CampaignId.decoder
                                        |> Decode.andThen
                                            (\campaignId ->
                                                Decode.field "name" Decode.string
                                                    |> Decode.andThen
                                                        (\name ->
                                                            Decode.field "description" (Decode.list Decode.string)
                                                                |> Decode.andThen
                                                                    (\description ->
                                                                        Decode.field "io" IO.decoder
                                                                            |> Decode.andThen
                                                                                (\io ->
                                                                                    Decode.field "initialBoard" Board.decoder
                                                                                        |> Decode.andThen
                                                                                            (\initialBoard ->
                                                                                                Decode.field "instructionTools" (Decode.array InstructionTool.decoder)
                                                                                                    |> Decode.andThen
                                                                                                        (\instructionTools ->
                                                                                                            Decode.succeed
                                                                                                                { id = id
                                                                                                                , index = index
                                                                                                                , campaignId = campaignId
                                                                                                                , name = name
                                                                                                                , description = description
                                                                                                                , io = io
                                                                                                                , initialBoard = initialBoard
                                                                                                                , instructionTools = instructionTools
                                                                                                                }
                                                                                                        )
                                                                                            )
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
                        levelDecoderV1

                    2 ->
                        levelDecoderV2

                    _ ->
                        Decode.fail
                            ("Unknown level decoder version: "
                                ++ String.fromInt version
                            )
            )
