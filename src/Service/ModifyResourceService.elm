module Service.ModifyResourceService exposing
    ( ModifyResourceInterface
    , deleteResourceById
    , gotDeleteResourceByIdResponse
    , gotSaveResourceResponse
    , saveResource
    , writeResourceToServer
    )

import Api.GCP as GCP
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater)
import Data.SaveError as SaveError exposing (SaveError)
import Data.Session exposing (Session, updateAccessToken)
import Data.VerifiedAccessToken as VerifiedAccessToken
import Json.Encode as Encode
import Service.LocalStorageService exposing (LocalStorageInterface, writeResourceToCurrentLocalStorage, writeResourceToExpectedLocalStorage)
import Service.ResourceType exposing (ResourceType, toIdParameterName, toPath)
import Update.SessionMsg exposing (SessionMsg)


type alias ModifyResourceInterface id res a =
    LocalStorageInterface id
        res
        { a
            | resourceType : ResourceType
            , encode : res -> Encode.Value
            , gotSaveResponseMessage : res -> Maybe SaveError -> SessionMsg
            , gotDeleteResponseMessage : id -> Maybe SaveError -> SessionMsg
            , toString : id -> String
        }


writeResourceToServer : ModifyResourceInterface id res a -> id -> Maybe res -> CmdUpdater Session SessionMsg
writeResourceToServer i id maybeResource session =
    case VerifiedAccessToken.getValid session.accessToken of
        Just accessToken ->
            -- TODO Update saving too
            case maybeResource of
                Just resource ->
                    ( i.setCurrentValue id maybeResource session
                    , GCP.put
                        |> GCP.withPath (toPath i.resourceType)
                        |> GCP.withAccessToken accessToken
                        |> GCP.withBody (i.encode resource)
                        |> GCP.request (SaveError.expect (i.gotSaveResponseMessage resource))
                    )

                Nothing ->
                    ( i.setCurrentValue id maybeResource session
                    , GCP.delete
                        |> GCP.withPath (toPath i.resourceType)
                        |> GCP.withStringQueryParameter (toIdParameterName i.resourceType) (i.toString id)
                        |> GCP.withAccessToken accessToken
                        |> GCP.request (SaveError.expect (i.gotDeleteResponseMessage id))
                    )

        Nothing ->
            ( session, Cmd.none )



-- SAVE


saveResource : ModifyResourceInterface id res a -> res -> CmdUpdater Session SessionMsg
saveResource i resource session =
    CmdUpdater.batch
        [ writeResourceToServer i resource.id (Just resource)
        , writeResourceToCurrentLocalStorage i resource.id (Just resource)
        ]
        session


gotSaveResourceResponse : ModifyResourceInterface id res a -> res -> Maybe SaveError -> CmdUpdater Session SessionMsg
gotSaveResourceResponse i resource maybeError =
    CmdUpdater.batch <|
        case maybeError of
            -- TODO Update saving
            Just error ->
                [ gotSaveError error
                ]

            Nothing ->
                [ i.setActualValue resource.id (Just resource)
                , writeResourceToExpectedLocalStorage i resource.id (Just resource)
                ]



-- DELETE


deleteResourceById : ModifyResourceInterface id res a -> id -> CmdUpdater Session SessionMsg
deleteResourceById i id session =
    CmdUpdater.batch
        [ writeResourceToServer i id Nothing
        , writeResourceToCurrentLocalStorage i id Nothing
        ]
        session


gotDeleteResourceByIdResponse : ModifyResourceInterface id res a -> id -> Maybe SaveError -> CmdUpdater Session SessionMsg
gotDeleteResourceByIdResponse i id maybeError =
    CmdUpdater.batch <|
        case maybeError of
            -- TODO Update saving
            Just error ->
                [ gotSaveError error
                ]

            Nothing ->
                [ i.setActualValue id Nothing
                , writeResourceToExpectedLocalStorage i id Nothing
                ]



-- PRIVATE


gotSaveError : SaveError.SaveError -> CmdUpdater Session msg
gotSaveError saveError session =
    case saveError of
        SaveError.InvalidAccessToken _ ->
            ( updateAccessToken VerifiedAccessToken.invalidate session
            , SaveError.consoleError saveError
            )

        _ ->
            ( session, SaveError.consoleError saveError )
