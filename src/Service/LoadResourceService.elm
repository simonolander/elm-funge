module Service.LoadResourceService exposing
    ( LoadResourceInterface
    , gotGetError
    , gotLoadResourceByIdResponse
    , loadPrivateResourceById
    , loadPublicResourceById
    , reloadPrivateResourceById
    , reloadPublicResourceById
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
import Service.RemoteDataDict exposing (RemoteDataDict, get, insertResult, loading, missingAccessToken)
import Service.RemoteResource exposing (RemoteResource, updateActual)
import Service.ResourceType exposing (ResourceType, toIdParameterName, toPath)
import Tuple exposing (pair)
import Update.SessionMsg exposing (SessionMsg)


type alias LoadResourceInterface id res comparable a =
    { a
        | getRemoteResource : Session -> RemoteResource comparable res a
        , setRemoteResource : RemoteResource comparable res a -> Updater Session
        , updateRemoteResource : Updater (RemoteResource comparable res a) -> Updater Session
        , resourceType : ResourceType
        , decoder : Decoder res
        , responseMsg : id -> Result GetError (Maybe res) -> SessionMsg
        , toKey : id -> comparable
        , toString : id -> String
        , mergeResource : id -> Maybe res -> CmdUpdater Session SessionMsg
    }


updateRemoteResource : LoadResourceInterface id res comparable a -> Updater (RemoteResource comparable res a) -> Updater Session
updateRemoteResource i updater session =
    i.getRemoteResource session
        |> updater
        |> flip i.setRemoteResource session



-- BY ID


loadPublicResourceById : LoadResourceInterface id res comparable a -> id -> Session -> ( Session, Cmd SessionMsg )
loadPublicResourceById =
    loadIfNotAsked reloadPublicResourceById


reloadPublicResourceById : LoadResourceInterface id res comparable a -> id -> Session -> ( Session, Cmd SessionMsg )
reloadPublicResourceById i id session =
    reloadWithOptionalAccessToken i id session Nothing


loadPrivateResourceById : LoadResourceInterface id res comparable a -> id -> Session -> ( Session, Cmd SessionMsg )
loadPrivateResourceById =
    loadIfNotAsked reloadPrivateResourceById


reloadPrivateResourceById : LoadResourceInterface id res comparable a -> id -> Session -> ( Session, Cmd SessionMsg )
reloadPrivateResourceById i id session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            reloadWithOptionalAccessToken i id session (Just accessToken)

        Nothing ->
            i.toKey id
                |> missingAccessToken
                |> updateActual
                |> flip (updateRemoteResource i) session
                |> flip pair Cmd.none



-- RESPONSE


gotLoadResourceByIdResponse : LoadResourceInterface id res comparable a -> id -> Result GetError (Maybe res) -> CmdUpdater Session SessionMsg
gotLoadResourceByIdResponse i id result oldSession =
    let
        session =
            i.toKey id
                |> flip insertResult result
                |> updateActual
                |> flip (updateRemoteResource i) oldSession
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
