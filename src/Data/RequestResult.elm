module Data.RequestResult exposing (RequestResult, badBody, constructor, convertToHttpError, extractMaybe, toTuple)

import Data.DetailedHttpError as DetailedHttpError exposing (DetailedHttpError)
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


badBody : Json.Decode.Error -> DetailedHttpError
badBody =
    Json.Decode.errorToString >> DetailedHttpError.BadBody 0


toTuple : RequestResult request error data -> ( request, Result error data )
toTuple { request, result } =
    ( request, result )


extractMaybe : RequestResult request error (Maybe data) -> Maybe (RequestResult request error data)
extractMaybe { request, result } =
    case result of
        Ok (Just value) ->
            Just { request = request, result = Ok value }

        Ok Nothing ->
            Nothing

        Err error ->
            Just { request = request, result = Err error }


convertToHttpError : RequestResult request Json.Decode.Error (Maybe value) -> RequestResult request DetailedHttpError value
convertToHttpError { request, result } =
    { request = request
    , result =
        case result of
            Ok (Just value) ->
                Ok value

            Ok Nothing ->
                Err DetailedHttpError.NotFound

            Err error ->
                Err (badBody error)
    }
