module Data.UserInfo exposing (UserInfo, decoder, encode, getUserName, loadFromServer, saveToLocalStorage)

import Api.GCP as GCP
import Data.AccessToken exposing (AccessToken)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Http
import Json.Decode
import Json.Encode
import Json.Encode.Extra
import Maybe.Extra
import Ports.LocalStorage as LocalStorage
import Url exposing (Url)


type alias UserInfo =
    { sub : String
    , givenName : Maybe String
    , familyName : Maybe String
    , nickname : Maybe String
    , name : Maybe String
    , picture : Maybe Url
    , locale : Maybe String
    , updatedAt : Maybe String
    }


getUserName : UserInfo -> String
getUserName userInfo =
    userInfo.name
        |> Maybe.Extra.orElse userInfo.givenName
        |> Maybe.Extra.orElse userInfo.familyName
        |> Maybe.Extra.orElse userInfo.nickname
        |> Maybe.withDefault userInfo.sub



-- JSON


encode : UserInfo -> Json.Encode.Value
encode userInfo =
    Json.Encode.object
        [ ( "sub", Json.Encode.string userInfo.sub )
        , ( "given_name", Json.Encode.Extra.maybe Json.Encode.string userInfo.givenName )
        , ( "family_name", Json.Encode.Extra.maybe Json.Encode.string userInfo.familyName )
        , ( "nickname", Json.Encode.Extra.maybe Json.Encode.string userInfo.nickname )
        , ( "name", Json.Encode.Extra.maybe Json.Encode.string userInfo.name )
        , ( "picture", Json.Encode.Extra.maybe Json.Encode.string (Maybe.map Url.toString userInfo.picture) )
        , ( "locale", Json.Encode.Extra.maybe Json.Encode.string userInfo.locale )
        , ( "updated_at", Json.Encode.Extra.maybe Json.Encode.string userInfo.updatedAt )
        ]


decoder : Json.Decode.Decoder UserInfo
decoder =
    Json.Decode.field "sub" Json.Decode.string
        |> Json.Decode.andThen
            (\sub ->
                Json.Decode.maybe (Json.Decode.field "given_name" Json.Decode.string)
                    |> Json.Decode.andThen
                        (\givenName ->
                            Json.Decode.maybe (Json.Decode.field "family_name" Json.Decode.string)
                                |> Json.Decode.andThen
                                    (\familyName ->
                                        Json.Decode.maybe (Json.Decode.field "nickname" Json.Decode.string)
                                            |> Json.Decode.andThen
                                                (\nickname ->
                                                    Json.Decode.maybe (Json.Decode.field "name" Json.Decode.string)
                                                        |> Json.Decode.andThen
                                                            (\name ->
                                                                Json.Decode.maybe (Json.Decode.field "picture" Json.Decode.string)
                                                                    |> Json.Decode.andThen
                                                                        (\picture ->
                                                                            Json.Decode.maybe (Json.Decode.field "locale" Json.Decode.string)
                                                                                |> Json.Decode.andThen
                                                                                    (\locale ->
                                                                                        Json.Decode.maybe (Json.Decode.field "updated_at" Json.Decode.string)
                                                                                            |> Json.Decode.andThen
                                                                                                (\updatedAt ->
                                                                                                    Json.Decode.succeed
                                                                                                        { sub = sub
                                                                                                        , givenName = givenName
                                                                                                        , familyName = familyName
                                                                                                        , nickname = nickname
                                                                                                        , name = name
                                                                                                        , picture = Maybe.andThen Url.fromString picture
                                                                                                        , locale = locale
                                                                                                        , updatedAt = updatedAt
                                                                                                        }
                                                                                                )
                                                                                    )
                                                                        )
                                                            )
                                                )
                                    )
                        )
            )



-- REST


loadFromServer : AccessToken -> (RequestResult AccessToken Http.Error UserInfo -> msg) -> Cmd msg
loadFromServer accessToken toMsg =
    let
        path =
            [ "userInfo" ]
    in
    GCP.authorizedGet path [] decoder (RequestResult.constructor accessToken >> toMsg) accessToken



-- LOCAL STORAGE


localStorageKey : LocalStorage.Key
localStorageKey =
    "userInfo"


loadFromLocalStorage : Cmd msg
loadFromLocalStorage =
    LocalStorage.storageGetItem localStorageKey


saveToLocalStorage : UserInfo -> Cmd msg
saveToLocalStorage campaign =
    LocalStorage.storageSetItem
        ( localStorageKey
        , encode campaign
        )


localStorageResponse : ( String, Json.Encode.Value ) -> Maybe (RequestResult String Json.Decode.Error (Maybe UserInfo))
localStorageResponse ( key, value ) =
    if key == localStorageKey then
        value
            |> Json.Decode.decodeValue (Json.Decode.nullable decoder)
            |> RequestResult.constructor "userInfo"
            |> Just

    else
        Nothing
