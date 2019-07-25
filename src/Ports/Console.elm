port module Ports.Console exposing (error, errorString, info, infoString)

import Json.Encode


port info : Json.Encode.Value -> Cmd msg


infoString : String -> Cmd msg
infoString =
    Json.Encode.string >> info


port error : Json.Encode.Value -> Cmd msg


errorString : String -> Cmd msg
errorString =
    Json.Encode.string >> error
