module Data.RequestResult exposing (RequestResult, constructor)

import Http


type alias RequestResult request data =
    { request : request
    , result : Result Http.Error data
    }


constructor : request -> Result Http.Error result -> RequestResult request result
constructor request result =
    { request = request
    , result = result
    }
