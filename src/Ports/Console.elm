port module Ports.Console exposing (error, errorString, log)

import Json.Encode


port log : Json.Encode.Value -> Cmd msg


port error : Json.Encode.Value -> Cmd msg


errorString : String -> Cmd msg
errorString =
    Json.Encode.string >> error
