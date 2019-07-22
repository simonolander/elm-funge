module Data.EndpointException exposing (EndpointException, decoder, encode)

import Json.Decode as Decode
import Json.Encode as Encode


type alias EndpointException =
    { status : Int
    , messages : List String
    }



-- JSON


encode : EndpointException -> Encode.Value
encode endpointException =
    Encode.object
        [ ( "status", Encode.int endpointException.status )
        , ( "messages", Encode.list Encode.string endpointException.messages )
        ]


decoder : Decode.Decoder EndpointException
decoder =
    Decode.field "status" Decode.int
        |> Decode.andThen
            (\status ->
                Decode.field "messages" (Decode.list Decode.string)
                    |> Decode.andThen
                        (\messages ->
                            Decode.succeed
                                { status = status
                                , messages = messages
                                }
                        )
            )
