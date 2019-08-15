module Data.EndpointResult exposing (EndpointResult(..), decoder, toString)

import Json.Decode as Decode


type EndpointResult
    = Ok
    | ConflictingId
    | Duplicate
    | NotFound
    | BadRequest (List String)
    | InvalidAccessToken (List String)
    | Forbidden (List String)
    | InternalServerError (List String)


toString : EndpointResult -> String
toString endpointResult =
    case endpointResult of
        Ok ->
            "Ok"

        ConflictingId ->
            "Conflicting id"

        Duplicate ->
            "Duplicate"

        NotFound ->
            "Not found"

        BadRequest messages ->
            String.join "\n" messages

        InvalidAccessToken messages ->
            String.join "\n" messages

        Forbidden messages ->
            String.join "\n" messages

        InternalServerError messages ->
            String.join "\n" messages



-- JSON


decoder : Decode.Decoder EndpointResult
decoder =
    let
        messagesDecoder : (List String -> Decode.Decoder b) -> Decode.Decoder b
        messagesDecoder f =
            Decode.field "messages" (Decode.list Decode.string) |> Decode.andThen f
    in
    Decode.field "tag" Decode.string
        |> Decode.andThen
            (\string ->
                case string of
                    "Ok" ->
                        Decode.succeed Ok

                    "ConflictingId" ->
                        Decode.succeed ConflictingId

                    "Duplicate" ->
                        Decode.succeed Duplicate

                    "NotFound" ->
                        Decode.succeed NotFound

                    "BadRequest" ->
                        messagesDecoder (Decode.succeed << BadRequest)

                    "InvalidAccessToken" ->
                        messagesDecoder (Decode.succeed << InvalidAccessToken)

                    "Forbidden" ->
                        messagesDecoder (Decode.succeed << Forbidden)

                    "InternalServerError" ->
                        messagesDecoder (Decode.succeed << InternalServerError)

                    other ->
                        Decode.fail ("Unknown tag: " ++ other)
            )
