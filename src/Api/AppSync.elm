module Api.AppSync exposing (GetLevelsResponse, Token, getLevels)

import Http
import Json.Decode
import Json.Encode


type alias Token =
    String


type alias GetLevelsResponse =
    { name : String
    }


getLevels : (Result Http.Error GetLevelsResponse -> a) -> Token -> Cmd a
getLevels msgFunction token =
    let
        getLevelsResponseDecoder : Json.Decode.Decoder GetLevelsResponse
        getLevelsResponseDecoder =
            Json.Decode.field "name" Json.Decode.string
                |> Json.Decode.andThen
                    (\name ->
                        Json.Decode.succeed
                            { name = name }
                    )
    in
    Http.request
        { method = "POST"
        , headers =
            [ Http.header "Authorization" token
            ]
        , url = "https://h6ebigamkzf3rpgoq6x6bv3voe.appsync-api.us-east-1.amazonaws.com/graphql"
        , body =
            Http.jsonBody <|
                Json.Encode.object
                    [ ( "query", Json.Encode.string "query { listLevels { name, external_id }}" )
                    ]
        , expect = Http.expectJson msgFunction getLevelsResponseDecoder
        , timeout = Nothing
        , tracker = Nothing
        }

getUserProgress