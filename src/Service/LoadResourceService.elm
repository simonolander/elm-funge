module Resource.LoadResourceService exposing
    ( LoadResourceInterface
    , gotLoadResponse
    , loadPrivate
    , loadPublic
    , reloadPrivate
    , reloadPublic
    )

import Api.GCP as GCP
import Basics.Extra exposing (flip)
import Data.CmdUpdater exposing (CmdUpdater, withCmd)
import Data.GetError exposing (GetError, expectMaybe)
import Data.Session exposing (Session, updateAccessToken)
import Data.Updater exposing (Updater)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Json.Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..))
import Resource.RemoteDataDict exposing (RemoteDataDict, get, insertResult, loading, missingAccessToken)
import Resource.ResourceType exposing (ResourceType, toIdParameterName, toPath)
import Tuple exposing (pair)
import Update.SessionMsg exposing (SessionMsg)


type alias LoadResourceInterface id res comparable a =
    { a
        | updateSession : Updater (RemoteDataDict comparable res) -> Updater Session
        , getResourceDict : Session -> RemoteDataDict comparable res
        , resourceType : ResourceType
        , decoder : Decoder res
        , responseMsg : id -> Result GetError (Maybe res) -> SessionMsg
        , toKey : id -> comparable
        , toString : id -> String
        , mergeResource : id -> Maybe res -> CmdUpdater Session SessionMsg
    }



-- STATIC


loadPublic : LoadResourceInterface id res comparable a -> id -> Session -> ( Session, Cmd SessionMsg )
loadPublic =
    loadIfNotAsked reloadPublic


reloadPublic : LoadResourceInterface id res comparable a -> id -> Session -> ( Session, Cmd SessionMsg )
reloadPublic i id session =
    reloadWithOptionalAccessToken i id session Nothing


loadPrivate : LoadResourceInterface id res comparable a -> id -> Session -> ( Session, Cmd SessionMsg )
loadPrivate =
    loadIfNotAsked reloadPrivate


reloadPrivate : LoadResourceInterface id res comparable a -> id -> Session -> ( Session, Cmd SessionMsg )
reloadPrivate i id session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            reloadWithOptionalAccessToken i id session (Just accessToken)

        Nothing ->
            i.toKey id
                |> missingAccessToken
                |> flip i.updateSession session
                |> flip pair Cmd.none



-- RESPONSE


gotLoadResponse : LoadResourceInterface id res comparable a -> id -> Result GetError (Maybe res) -> CmdUpdater Session SessionMsg
gotLoadResponse i id result oldSession =
    let
        session =
            i.toKey id
                |> flip insertResult result
                |> flip i.updateSession oldSession
    in
    case result of
        Ok maybeResource ->
            i.mergeResource id maybeResource session

        Err error ->
            gotGetError error session



-- PRIVATE


loadIfNotAsked loader i id session =
    if
        i.getResourceDict session
            |> get (i.toKey id)
            |> RemoteData.isNotAsked
    then
        loader i id session

    else
        ( session, Cmd.none )


reloadWithOptionalAccessToken i id session maybeAccessToken =
    let
        withAccessToken =
            Maybe.map GCP.withAccessToken maybeAccessToken
                |> Maybe.withDefault identity
    in
    i.toKey id
        |> loading
        |> flip i.updateSession session
        |> withCmd
            (withAccessToken GCP.get
                |> GCP.withPath (toPath i.resourceType)
                |> GCP.withStringQueryParameter (toIdParameterName i.resourceType) (i.toString id)
                |> GCP.request (expectMaybe i.decoder (i.responseMsg id))
            )


gotGetError : GetError -> CmdUpdater Session msg
gotGetError saveError session =
    case saveError of
        Data.GetError.InvalidAccessToken _ ->
            ( updateAccessToken VerifiedAccessToken.invalidate session
            , Data.GetError.consoleError saveError
            )

        _ ->
            ( session, Data.GetError.consoleError saveError )
