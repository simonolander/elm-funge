module Resource.ResourceUpdater exposing
    ( PrivateInterface
    , PublicInterface
    , Resolution(..)
    , clear
    , deleteResourceById
    , expectedLocalStorageResponse
    , getConflictResolution
    , getResourceById
    , gotDeleteResourceByIdResponse
    , gotGetError
    , gotLoadResourceByIdResponse
    , gotSaveError
    , gotSaveResourceResponse
    , loadResourceById
    , loadResourcesByIds
    , localStorageResponse
    , resolveConflict
    , resolveManuallyKeepLocal
    , resolveManuallyKeepServer
    , saveResource
    , toConflict
    , toCurrentLocalStorageKey
    , toExpectedLocalStorageKey
    , writeActualResource
    , writeExpectedResource
    , writeLocalResource
    )

import Api.GCP as GCP
import Basics.Extra exposing (flip)
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withCmd)
import Data.GetError exposing (GetError)
import Data.OneOrBoth exposing (OneOrBoth(..))
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.SaveError
import Data.SaveRequest exposing (SaveRequest(..))
import Data.Session as Session exposing (Session)
import Data.Updater exposing (Updater)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Dict
import Extra.Result
import Json.Decode exposing (Decoder)
import Json.Encode
import Json.Encode.Extra
import Maybe.Extra
import Ports.Console as Console
import Ports.LocalStorage exposing (decodeLocalStorageEntry, storageSetItem)
import RemoteData exposing (RemoteData(..))
import Resource.ModifiableResource as Resource exposing (ModifiableRemoteResource, updateActual, updateExpected, updateLocal, updateSaving)
import Update.SessionMsg exposing (SessionMsg)


type alias PublicMethods id res a b =
    { b
        | getResource : Session -> ModifiableRemoteResource id res a
        , updateResource : Updater (Resource.ModifiableRemoteResource id res a) -> Updater Session
        , path : List String
        , idParameterName : String
        , decoder : Decoder res
        , encode : res -> Json.Encode.Value
        , gotLoadResourceResponse : id -> Result Data.GetError.GetError (Maybe res) -> SessionMsg
        , idToString : id -> String
        , idFromString : String -> id
        , localStoragePrefix : String
        , empty : ModifiableRemoteResource id res a
    }


type alias PrivateMethods res id a =
    { a
        | gotSaveResponseMessage : res -> Maybe Data.SaveError.SaveError -> SessionMsg
        , gotDeleteResponseMessage : id -> Maybe Data.SaveError.SaveError -> SessionMsg
        , equals : res -> res -> Bool
    }


type alias PublicInterface id res a =
    PublicMethods id res a {}


type alias PrivateInterface id res a =
    PublicMethods id res a (PrivateMethods res id {})



-- GET


getResourceById : PublicMethods comparableId res a b -> comparableId -> Session -> RemoteData GetError (Maybe res)
getResourceById interface id session =
    -- TODO Think about how this is supposed to work
    case
        interface.getResource session
            |> .actual
            |> Dict.get id
    of
        Nothing ->
            NotAsked

        Just Loading ->
            Loading

        Just (Failure error) ->
            Failure error

        _ ->
            interface.getResource session
                |> .local
                |> Dict.get id
                |> Maybe.Extra.join
                |> Success



-- LOAD


loadResourcesByIds : PublicMethods comparableId res a b -> List comparableId -> CmdUpdater Session SessionMsg
loadResourcesByIds interface ids session =
    List.map (loadResourceById interface) ids
        |> flip CmdUpdater.batch session


loadResourceById : PublicMethods comparableId res a b -> comparableId -> CmdUpdater Session SessionMsg
loadResourceById interface id session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            if
                interface.getResource session
                    |> .actual
                    |> Dict.get id
                    |> Maybe.withDefault NotAsked
                    |> RemoteData.isNotAsked
            then
                Dict.insert id Loading
                    |> updateActual
                    |> flip interface.updateResource session
                    |> withCmd
                        (GCP.get
                            |> GCP.withPath interface.path
                            |> GCP.withAccessToken accessToken
                            |> GCP.withStringQueryParameter interface.idParameterName id
                            |> GCP.request (Data.GetError.expectMaybe interface.decoder (interface.gotLoadResourceResponse id))
                        )

            else
                ( session, Cmd.none )

        Nothing ->
            Dict.insert id NotAsked
                |> updateActual
                |> flip interface.updateResource session
                |> CmdUpdater.id


gotLoadResourceByIdResponse : PublicMethods comparableId res a b -> comparableId -> Result GetError (Maybe res) -> CmdUpdater Session SessionMsg
gotLoadResourceByIdResponse interface id result oldSession =
    let
        session =
            RemoteData.fromResult result
                |> Dict.insert id
                |> updateActual
                |> flip interface.updateResource oldSession
    in
    case result of
        Ok maybeActual ->
            resolveConflict interface id maybeActual session

        Err error ->
            gotGetError error session



-- SAVE


saveResource : PrivateInterface comparableId res a -> res -> CmdUpdater Session SessionMsg
saveResource interface resource =
    CmdUpdater.batch
        [ writeLocalResource interface resource.id (Just resource)
        , writeActualResource interface resource.id (Just resource)
        ]


gotSaveResourceResponse : PublicMethods comparableId res a b -> res -> Maybe Data.SaveError.SaveError -> CmdUpdater Session msg
gotSaveResourceResponse interface resource maybeError =
    CmdUpdater.batch <|
        case maybeError of
            Just error ->
                [ (Dict.insert resource.id (Error error)
                    |> updateSaving
                    |> interface.updateResource
                  )
                    >> CmdUpdater.id
                , gotSaveError error
                ]

            Nothing ->
                [ (Dict.insert resource.id (Saved (Just resource))
                    |> updateSaving
                    |> interface.updateResource
                  )
                    >> CmdUpdater.id
                , (Dict.insert resource.id (Success (Just resource))
                    |> updateActual
                    |> interface.updateResource
                  )
                    >> CmdUpdater.id
                , writeExpectedResource interface resource.id (Just resource)
                ]



-- DELETE


deleteResourceById : PublicMethods comparableId res a b -> comparableId -> CmdUpdater Session SessionMsg
deleteResourceById interface id =
    CmdUpdater.batch
        [ writeLocalResource interface id Nothing
        , writeActualResource interface id Nothing
        ]


gotDeleteResourceByIdResponse : PublicMethods comparableId res a b -> comparableId -> Maybe Data.SaveError.SaveError -> CmdUpdater Session msg
gotDeleteResourceByIdResponse interface id maybeError =
    CmdUpdater.batch <|
        case maybeError of
            Just error ->
                [ (Dict.insert id (Error error)
                    |> updateSaving
                    |> interface.updateResource
                  )
                    >> CmdUpdater.id
                , gotSaveError error
                ]

            Nothing ->
                [ (Dict.insert id (Saved Nothing)
                    |> updateSaving
                    |> interface.updateResource
                  )
                    >> CmdUpdater.id
                , (Dict.insert id (Success Nothing)
                    |> updateActual
                    |> interface.updateResource
                  )
                    >> CmdUpdater.id
                , writeExpectedResource interface id Nothing
                ]



-- PERSISTENCE REQUEST


clear : PublicMethods comparableId res a b -> CmdUpdater Session msg
clear interface session =
    ( interface.updateResource (always interface.empty) session
    , Cmd.batch
        [ interface.getResource session
            |> .local
            |> Dict.keys
            |> List.map (toCurrentLocalStorageKey interface)
            |> List.map Ports.LocalStorage.storageRemoveItem
            |> Cmd.batch
        , interface.getResource session
            |> .expected
            |> Dict.keys
            |> List.map (toExpectedLocalStorageKey interface)
            |> List.map Ports.LocalStorage.storageRemoveItem
            |> Cmd.batch
        ]
    )


writeLocalResource : PublicMethods comparableId res a b -> comparableId -> Maybe res -> CmdUpdater Session msg
writeLocalResource interface id maybeResource session =
    ( Dict.insert id maybeResource
        |> updateLocal
        |> flip interface.updateResource session
    , storageSetItem
        ( toCurrentLocalStorageKey interface id
        , Json.Encode.Extra.maybe interface.encode maybeResource
        )
    )


writeExpectedResource : PublicMethods comparableId res a b -> comparableId -> Maybe res -> CmdUpdater Session msg
writeExpectedResource interface id maybeResource session =
    ( Dict.insert id maybeResource
        |> updateExpected
        |> flip interface.updateResource session
    , storageSetItem
        ( toExpectedLocalStorageKey interface id
        , Json.Encode.Extra.maybe interface.encode maybeResource
        )
    )


writeActualResource : PrivateInterface comparableId res a -> comparableId -> Maybe res -> CmdUpdater Session SessionMsg
writeActualResource interface id maybeResource session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            case maybeResource of
                Just resource ->
                    ( Dict.insert id (Saving (Just resource))
                        |> updateSaving
                        |> flip interface.updateResource session
                    , GCP.put
                        |> GCP.withPath interface.path
                        |> GCP.withAccessToken accessToken
                        |> GCP.withBody (interface.encode resource)
                        |> GCP.request (Data.SaveError.expect (interface.gotSaveResponseMessage resource))
                    )

                Nothing ->
                    ( Dict.insert id (Saving Nothing)
                        |> updateSaving
                        |> flip interface.updateResource session
                    , GCP.delete
                        |> GCP.withPath interface.path
                        |> GCP.withStringQueryParameter interface.idParameterName id
                        |> GCP.withAccessToken accessToken
                        |> GCP.request (Data.SaveError.expect (interface.gotDeleteResponseMessage id))
                    )

        Nothing ->
            ( session, Cmd.none )



-- CONFLICT RESOLUTION


type Resolution data
    = Merge (Maybe data) Bool Bool Bool
    | Conflict (OneOrBoth data)


toConflict : Resolution a -> Maybe (OneOrBoth a)
toConflict resolution =
    case resolution of
        Merge _ _ _ _ ->
            Nothing

        Conflict oneOrBoth ->
            Just oneOrBoth


getConflictResolution : PrivateInterface comparableId res a -> comparableId -> Maybe res -> Session -> Resolution res
getConflictResolution interface id maybeActual session =
    let
        maybeLocal =
            interface.getResource session
                |> .local
                |> Dict.get id

        maybeExpected =
            interface.getResource session
                |> .expected
                |> Dict.get id

        equals =
            interface.equals
    in
    case ( maybeLocal, maybeExpected, maybeActual ) of
        ( Just (Just local), Just (Just expected), Just actual ) ->
            if equals local expected then
                -- 1 1 !
                Merge (Just actual) True True False

            else if equals local actual then
                -- 1 2 1
                Merge (Just actual) False True False

            else if equals expected actual then
                -- 1 2 2
                Merge (Just local) False False True

            else
                -- 1 2 3
                Conflict (Both local actual)

        ( Just (Just local), Just (Just expected), Nothing ) ->
            if equals local expected then
                -- 1 1 0
                Merge Nothing True True False

            else
                -- 1 2 0
                Conflict (First local)

        ( Just (Just local), Just Nothing, Just actual ) ->
            if equals local actual then
                -- 1 0 1
                Merge (Just actual) False True False

            else
                -- 1 0 2
                Conflict (Both local actual)

        ( Just (Just local), Just Nothing, Nothing ) ->
            -- 1 0 0
            Merge (Just local) False False True

        ( Just (Just local), Nothing, Just actual ) ->
            if equals local actual then
                -- 1 ? 1
                Merge (Just actual) False True False

            else
                -- 1 ? 2
                Conflict (Both local actual)

        ( Just (Just local), Nothing, Nothing ) ->
            -- 1 0 0
            Merge (Just local) False False True

        ( Just Nothing, Just (Just expected), Just actual ) ->
            if equals expected actual then
                -- 0 1 1
                Merge Nothing False False True

            else
                -- 0 1 2
                Conflict (Second actual)

        ( Just Nothing, Just Nothing, Just actual ) ->
            -- 0 0 1
            Merge (Just actual) True True False

        ( Just Nothing, _, Nothing ) ->
            -- 0 ! 0
            Merge Nothing True True False

        ( Just Nothing, Nothing, Just actual ) ->
            -- 0 ? 1
            Conflict (Second actual)

        ( Nothing, _, actual ) ->
            -- ? ! !
            Merge actual True True False


resolveConflict : PublicMethods comparableId res a b -> comparableId -> Maybe res -> CmdUpdater Session SessionMsg
resolveConflict interface id maybeActual session =
    flip CmdUpdater.batch session <|
        case getConflictResolution interface id maybeActual session of
            Merge data shouldWriteLocal shouldWriteExpected shouldWriteActual ->
                Maybe.Extra.values
                    [ if shouldWriteLocal then
                        Just (writeLocalResource interface id data)

                      else
                        Nothing
                    , if shouldWriteExpected then
                        Just (writeExpectedResource interface id data)

                      else
                        Nothing
                    , if shouldWriteActual then
                        Just (writeActualResource interface id data)

                      else
                        Nothing
                    ]

            Conflict _ ->
                []


resolveManuallyKeepLocal : PublicMethods comparableId res a b -> comparableId -> CmdUpdater Session SessionMsg
resolveManuallyKeepLocal interface id session =
    case
        interface.getResource session
            |> .local
            |> Dict.get id
    of
        Just maybeResource ->
            writeActualResource interface id maybeResource session

        Nothing ->
            ( session
            , Console.errorString "32IY3Wkb    Cannot keep local resource: nothing to keep"
            )


resolveManuallyKeepServer : PublicMethods comparableId res a b -> comparableId -> CmdUpdater Session SessionMsg
resolveManuallyKeepServer interface id session =
    case
        interface.getResource session
            |> .actual
            |> Dict.get id
            |> Maybe.andThen RemoteData.toMaybe
    of
        Just maybeResource ->
            CmdUpdater.batch
                [ writeExpectedResource interface id maybeResource
                , writeLocalResource interface id maybeResource
                ]
                session

        Nothing ->
            ( session
            , Console.errorString "taNV569E    Cannot keep server resource, it's not successfully loaded."
            )



-- LOCAL STORAGE


initFromLocalStorage : PublicMethods comparableId res a b -> List ( String, Json.Encode.Value ) -> ( ModifiableRemoteResource comparableId res a, List ( String, Json.Decode.Error ) )
initFromLocalStorage interface localStorageEntries =
    let
        { decoder, empty } =
            interface

        ( localBlueprints, localErrors ) =
            List.filterMap (decodeLocalStorageEntry (fromCurrentLocalStorageKey interface) (Json.Decode.nullable decoder)) localStorageEntries
                |> Extra.Result.split

        ( expectedBlueprints, expectedErrors ) =
            List.filterMap (decodeLocalStorageEntry (fromExpectedLocalStorageKey interface) (Json.Decode.nullable decoder)) localStorageEntries
                |> Extra.Result.split
    in
    ( { empty
        | local = Dict.fromList localBlueprints
        , expected = Dict.fromList expectedBlueprints
      }
    , List.concat
        [ localErrors
        , expectedErrors
        ]
    )


toCurrentLocalStorageKey : PublicMethods id res a b -> id -> String
toCurrentLocalStorageKey interface id =
    String.join "." [ interface.localStoragePrefix, interface.idToString id ]


fromCurrentLocalStorageKey : PublicMethods id res a b -> String -> Maybe id
fromCurrentLocalStorageKey interface localStorageKey =
    case String.split "." localStorageKey of
        prefix :: id :: [] ->
            if prefix == interface.localStoragePrefix then
                Just (interface.idFromString id)

            else
                Nothing


toExpectedLocalStorageKey : PublicMethods id res a b -> id -> String
toExpectedLocalStorageKey interface id =
    String.join "." [ toCurrentLocalStorageKey interface id, "remote" ]


fromExpectedLocalStorageKey : PublicMethods id res a b -> String -> Maybe id
fromExpectedLocalStorageKey interface localStorageKey =
    case String.split "." localStorageKey of
        prefix :: id :: "remote" :: [] ->
            if prefix == interface.localStoragePrefix then
                Just (interface.idFromString id)

            else
                Nothing


localStorageResponse : PublicMethods String res a b -> ( String, Json.Encode.Value ) -> Maybe (RequestResult String Json.Decode.Error (Maybe res))
localStorageResponse interface ( key, value ) =
    case fromCurrentLocalStorageKey interface key of
        Just id ->
            Json.Decode.decodeValue (Json.Decode.nullable interface.decoder) value
                |> RequestResult.constructor id
                |> Just

        Nothing ->
            Nothing


expectedLocalStorageResponse : PublicMethods String res a b -> ( String, Json.Encode.Value ) -> Maybe (RequestResult String Json.Decode.Error (Maybe res))
expectedLocalStorageResponse interface ( key, value ) =
    case fromExpectedLocalStorageKey interface key of
        Just id ->
            Json.Decode.decodeValue (Json.Decode.nullable interface.decoder) value
                |> RequestResult.constructor id
                |> Just

        Nothing ->
            Nothing



-- GENERAL ERROR


gotSaveError : Data.SaveError.SaveError -> CmdUpdater Session msg
gotSaveError saveError session =
    case saveError of
        Data.SaveError.InvalidAccessToken _ ->
            ( Session.updateAccessToken VerifiedAccessToken.invalidate session
            , Data.SaveError.consoleError saveError
            )

        _ ->
            ( session, Data.SaveError.consoleError saveError )


gotGetError : GetError -> CmdUpdater Session msg
gotGetError saveError session =
    case saveError of
        Data.GetError.InvalidAccessToken _ ->
            ( Session.updateAccessToken VerifiedAccessToken.invalidate session
            , Data.GetError.consoleError saveError
            )

        _ ->
            ( session, Data.GetError.consoleError saveError )
