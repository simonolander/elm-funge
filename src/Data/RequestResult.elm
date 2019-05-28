module Data.RequestResult exposing (RequestResult, badBody, constructor, notFound)

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
