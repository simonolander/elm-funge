module Data.UserInfo exposing (UserInfo, decoder, encode, loadFromServer)

import Api.GCP as GCP
import Data.AuthorizationToken exposing (AuthorizationToken)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Http
import Json.Decode
import Json.Encode
import Json.Encode.Extra
import Maybe.Extra


type alias UserInfo =
    { sub : Maybe String
    , givenName : Maybe String
    , familyName : Maybe String
    , nickname : Maybe String
    , name : Maybe String
    , picture : Maybe String
    , locale : Maybe String
    , updatedAt : Maybe String
    }


getUserName : UserInfo -> String
getUserName userInfo =
    userInfo.familyName
        |> Maybe.Extra.orElse userInfo.givenName
        |> Maybe.Extra.orElse userInfo.givenName
        |> Maybe.withDefault "No name"



-- JSON


encode : UserInfo -> Json.Encode.Value
encode userInfo =
    Json.Encode.object
        [ ( "sub", Json.Encode.Extra.maybe Json.Encode.string userInfo.sub )
        , ( "given_name", Json.Encode.Extra.maybe Json.Encode.string userInfo.givenName )
        , ( "family_name", Json.Encode.Extra.maybe Json.Encode.string userInfo.familyName )
        , ( "nickname", Json.Encode.Extra.maybe Json.Encode.string userInfo.nickname )
        , ( "name", Json.Encode.Extra.maybe Json.Encode.string userInfo.name )
        , ( "picture", Json.Encode.Extra.maybe Json.Encode.string userInfo.picture )
        , ( "locale", Json.Encode.Extra.maybe Json.Encode.string userInfo.locale )
        , ( "updated_at", Json.Encode.Extra.maybe Json.Encode.string userInfo.updatedAt )
        ]


decoder : Json.Decode.Decoder UserInfo
decoder =
    Json.Decode.field "sub" (Json.Decode.nullable Json.Decode.string)
        |> Json.Decode.andThen
            (\sub ->
                Json.Decode.field "given_name" (Json.Decode.nullable Json.Decode.string)
                    |> Json.Decode.andThen
                        (\givenName ->
                            Json.Decode.field "family_name" (Json.Decode.nullable Json.Decode.string)
                                |> Json.Decode.andThen
                                    (\familyName ->
                                        Json.Decode.field "nickname" (Json.Decode.nullable Json.Decode.string)
                                            |> Json.Decode.andThen
                                                (\nickname ->
                                                    Json.Decode.field "name" (Json.Decode.nullable Json.Decode.string)
                                                        |> Json.Decode.andThen
                                                            (\name ->
                                                                Json.Decode.field "picture" (Json.Decode.nullable Json.Decode.string)
                                                                    |> Json.Decode.andThen
                                                                        (\picture ->
                                                                            Json.Decode.field "locale" (Json.Decode.nullable Json.Decode.string)
                                                                                |> Json.Decode.andThen
                                                                                    (\locale ->
                                                                                        Json.Decode.field "updated_at" (Json.Decode.nullable Json.Decode.string)
                                                                                            |> Json.Decode.andThen
                                                                                                (\updatedAt ->
                                                                                                    Json.Decode.succeed
                                                                                                        { sub = sub
                                                                                                        , givenName = givenName
                                                                                                        , familyName = familyName
                                                                                                        , nickname = nickname
                                                                                                        , name = name
                                                                                                        , picture = picture
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


loadFromServer : AuthorizationToken -> (RequestResult AuthorizationToken Http.Error UserInfo -> msg) -> Cmd msg
loadFromServer accessToken toMsg =
    let
        path =
            [ "userInfo" ]
    in
    GCP.authorizedGet path [] decoder (RequestResult.constructor accessToken >> toMsg) accessToken
