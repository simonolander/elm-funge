module Data.RequestResult exposing (RequestResult, badBody, constructor, split, toTuple)

import Data.GetError exposing (GetError(..))
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


badBody : Json.Decode.Error -> GetError
badBody =
    Json.Decode.errorToString >> Other


toTuple : RequestResult request error data -> ( request, Result error data )
toTuple { request, result } =
    ( request, result )


split : List (RequestResult request error data) -> ( List ( request, data ), List ( request, error ) )
split list =
    case list of
        { request, result } :: tail ->
            let
                ( values, errors ) =
                    split tail
            in
            case result of
                Ok value ->
                    ( ( request, value ) :: values, errors )

                Err error ->
                    ( values, ( request, error ) :: errors )

        [] ->
            ( [], [] )
