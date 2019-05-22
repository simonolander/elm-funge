module Data.RequestResult exposing (RequestResult)

import Http


type alias RequestResult request data =
    { request : request
    , result : Result Http.Error data
    }
