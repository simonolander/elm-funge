module Data.UserInfo exposing (UserInfo, decoder, encode)

import Json.Decode as Decode
import Json.Encode as Encode


type alias UserInfo =
    { name : String }



-- JSON


encode : UserInfo -> Encode.Value
encode userInfo =
    Encode.object
        [ ( "name", Encode.string userInfo.name ) ]


decoder : Decode.Decoder UserInfo
decoder =
    Decode.field "name" Decode.string
        |> Decode.andThen
            (\name ->
                Decode.succeed
                    { name = name }
            )
