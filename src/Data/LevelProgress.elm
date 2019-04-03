module Data.LevelProgress exposing (LevelProgress)

import Data.Draft as Draft exposing (Draft)
import Data.Level as Level exposing (Level)
import Json.Decode as Decode
import Json.Encode as Encode


type alias LevelProgress =
    { level : Level
    , drafts : List Draft
    }



-- JSON


encode : LevelProgress -> Encode.Value
encode levelProgress =
    Encode.object
        [ ( "level", Level.encode levelProgress.level )
        , ( "drafts", Encode.list Draft.encode levelProgress.drafts )
        ]


decoder : Decode.Decoder LevelProgress
decoder =
    Decode.field "level" Level.decoder
        |> Decode.andThen
            (\level ->
                Decode.field "drafts" (Decode.list Draft.decoder)
                    |> Decode.andThen
                        (\drafts ->
                            Decode.succeed
                                { level = level
                                , drafts = drafts
                                }
                        )
            )
