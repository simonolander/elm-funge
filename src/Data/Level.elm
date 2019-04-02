module Data.Level exposing (Level, decoder, encode)

import Data.Board as Board exposing (Board)
import Data.IO as IO exposing (IO)
import Data.InstructionTool as InstructionTool exposing (InstructionTool)
import Data.LevelId exposing (LevelId)
import Json.Decode as Decode exposing (Decoder, andThen, fail, field, succeed)
import Json.Encode
    exposing
        ( Value
        , int
        , list
        , object
        , string
        )


type alias Level =
    { id : LevelId
    , name : String
    , description : List String
    , io : IO
    , initialBoard : Board
    , instructionTools : List InstructionTool
    }



-- JSON


encode : Level -> Value
encode level =
    object
        [ ( "version", int 1 )
        , ( "id", string level.id )
        , ( "name", string level.name )
        , ( "description", list string level.description )
        , ( "io", IO.encode level.io )
        , ( "initialBoard", Board.encode level.initialBoard )
        , ( "instructionTools", list InstructionTool.encode level.instructionTools )
        ]


decoder : Decoder Level
decoder =
    let
        levelDecoderV1 =
            field "id" Decode.string
                |> andThen
                    (\id ->
                        field "name" Decode.string
                            |> andThen
                                (\name ->
                                    field "description" (Decode.list Decode.string)
                                        |> andThen
                                            (\description ->
                                                field "io" IO.decoder
                                                    |> andThen
                                                        (\io ->
                                                            field "initialBoard" Board.decoder
                                                                |> andThen
                                                                    (\initialBoard ->
                                                                        field "instructionTools" (Decode.list InstructionTool.decoder)
                                                                            |> andThen
                                                                                (\instructionTools ->
                                                                                    succeed
                                                                                        { id = id
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
    in
    field "version" Decode.int
        |> andThen
            (\version ->
                case version of
                    1 ->
                        levelDecoderV1

                    _ ->
                        fail
                            ("Unknown level decoder version: "
                                ++ String.fromInt version
                            )
            )
