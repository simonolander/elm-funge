module Data.RequestResult exposing (RequestResult, badBody, constructor, convertToHttpError, notFound, toTuple)

import Http
import Json.Decode


type alias RequestResult request error data =
    { request : request
    , result : Result error data
    }


constructor : request -> Result error result -> RequestResult request error result
constructor request result =
    { request = request
    , result = result
    }


notFound : Http.Error
notFound =
    Http.BadStatus 404


badBody : Json.Decode.Error -> Http.Error
badBody =
    Json.Decode.errorToString >> Http.BadBody


toTuple : RequestResult request error data -> ( request, Result error data )
toTuple { request, result } =
    ( request, result )


convertToHttpError : RequestResult request Json.Decode.Error (Maybe value) -> RequestResult request Http.Error value
convertToHttpError { request, result } =
    { request = request
    , result =
        case result of
            Ok (Just value) ->
                Ok value

            Ok Nothing ->
                Err notFound

            Err error ->
                Err (badBody error)
    }
