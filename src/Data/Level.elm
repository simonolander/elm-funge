module Data.Level exposing (Level, decoder, encode, loadFromLocalStorage, localStorageKey, saveToLocalStorage, withInstructionTool)

import Array exposing (Array)
import Data.Board as Board exposing (Board)
import Data.IO as IO exposing (IO)
import Data.InstructionTool as InstructionTool exposing (InstructionTool)
import Data.LevelId exposing (LevelId)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage as LocalStorage


type alias Level =
    { id : LevelId
    , index : Int
    , name : String
    , description : List String
    , io : IO
    , initialBoard : Board
    , instructionTools : Array InstructionTool
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



-- JSON


encode : Level -> Encode.Value
encode level =
    Encode.object
        [ ( "version", Encode.int 1 )
        , ( "id", Encode.string level.id )
        , ( "index", Encode.int level.index )
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

        levelDecoderV2 =
            Decode.field "id" Decode.string
                |> Decode.andThen
                    (\id ->
                        Decode.field "index" Decode.int
                            |> Decode.andThen
                                (\index ->
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
