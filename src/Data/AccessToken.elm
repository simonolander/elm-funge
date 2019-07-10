module Data.AccessToken exposing
    ( AccessToken
    , decoder
    , encode
    , fromString
    , loadFromLocalStorage
    , localStorageKey
    , localStorageResponse
    , saveToLocalStorage
    , toString
    )

import Data.RequestResult as RequestResult exposing (RequestResult)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage as LocalStorage


type AccessToken
    = AccessToken String


toString : AccessToken -> String
toString (AccessToken accessToken) =
    accessToken


fromString : String -> AccessToken
fromString =
    AccessToken



-- LOCAL STORAGE


localStorageKey : LocalStorage.Key
localStorageKey =
    "accessToken"


loadFromLocalStorage : Cmd msg
loadFromLocalStorage =
    LocalStorage.storageGetItem localStorageKey


saveToLocalStorage : AccessToken -> Cmd msg
saveToLocalStorage campaign =
    LocalStorage.storageSetItem
        ( localStorageKey
        , encode campaign
        )


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult String Decode.Error (Maybe AccessToken))
localStorageResponse ( key, value ) =
    if key == localStorageKey then
        value
            |> Decode.decodeValue (Decode.nullable decoder)
            |> RequestResult.constructor "accessToken"
            |> Just

    else
        Nothing



-- JSON


encode : AccessToken -> Encode.Value
encode accessToken =
    Encode.object
        [ ( "version", Encode.int 1 )
        , ( "accessToken", Encode.string (toString accessToken) )
        ]


decoder : Decode.Decoder AccessToken
decoder =
    Decode.field "version" Decode.int
        |> Decode.andThen
            (\version ->
                case version of
                    1 ->
                        Decode.field "accessToken" Decode.string
                            |> Decode.andThen
                                (\accessToken ->
                                    Decode.succeed
                                        (fromString accessToken)
                                )

                    _ ->
                        Decode.fail ("Unknown version: " ++ String.fromInt version)
            )
