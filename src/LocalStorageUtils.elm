module LocalStorageUtils exposing
    ( clear
    , cmdPort
    , funnelDict
    , getBoard
    , getLevelSolved
    , initialState
    , prefix
    , putBoard
    , putLevelSolved
    , send
    , simulate
    , storageHandler
    , subscriptions
    , update
    )

import History
import Json.Decode as Decode
import Json.Encode as Encode
import JsonUtils
import LevelProgressUtils
import Model exposing (..)
import PortFunnel.LocalStorage as LocalStorage
import PortFunnels


simulate : Bool
simulate =
    False


prefix : LocalStorage.Prefix
prefix =
    "elm-funge"


cmdPort : LocalStorage.Value -> Cmd Msg
cmdPort =
    PortFunnels.getCmdPort (LocalStorageMsg << LocalStorageProcess) LocalStorage.moduleName simulate


subscriptions =
    PortFunnels.subscriptions


funnelDict : PortFunnels.FunnelDict Model Msg
funnelDict =
    PortFunnels.makeFunnelDict [ PortFunnels.LocalStorageHandler storageHandler ] (\_ _ -> cmdPort)


initialState : PortFunnels.State
initialState =
    PortFunnels.initialState prefix


send : LocalStorage.Message -> LocalStorage.State -> Cmd Msg
send message funnelState =
    LocalStorage.send
        cmdPort
        message
        funnelState


clear : PortFunnels.State -> Cmd Msg
clear state =
    send (LocalStorage.clear "") state.storage


putLevelSolved : LevelId -> PortFunnels.State -> Cmd Msg
putLevelSolved levelId state =
    send
        (LocalStorage.put (levelId ++ ".solved")
            (True
                |> Encode.bool
                |> Just
            )
        )
        state.storage


getLevelSolved : LevelId -> PortFunnels.State -> Cmd Msg
getLevelSolved levelId state =
    send
        (LocalStorage.get (levelId ++ ".solved"))
        state.storage


putBoard : LevelId -> Board -> PortFunnels.State -> Cmd Msg
putBoard levelId board state =
    send
        (LocalStorage.put (levelId ++ ".boards.0")
            (board
                |> JsonUtils.encodeBoard
                |> Just
            )
        )
        state.storage


getBoard : LevelId -> PortFunnels.State -> Cmd Msg
getBoard levelId state =
    send
        (LocalStorage.get (levelId ++ ".boards.0"))
        state.storage


update : Model -> LocalStorageMsg -> ( Model, Cmd Msg )
update model msg =
    case msg of
        LocalStorageProcess value ->
            case
                PortFunnels.processValue
                    funnelDict
                    value
                    model.funnelState
                    model
            of
                Ok res ->
                    res

                Err message ->
                    ( model, Cmd.none )

        Clear ->
            ( model, clear model.funnelState )


storageHandler : LocalStorage.Response -> PortFunnels.State -> Model -> ( Model, Cmd Msg )
storageHandler response state mdl =
    let
        model =
            { mdl | funnelState = state }
    in
    case response of
        LocalStorage.GetResponse { key, value } ->
            case ( String.split "." key, value ) of
                ( levelId :: "solved" :: _, Just v ) ->
                    case Decode.decodeValue Decode.bool v of
                        Ok True ->
                            ( model
                                |> LevelProgressUtils.setLevelProgressSolvedInModel levelId
                            , Cmd.none
                            )

                        _ ->
                            ( model, Cmd.none )

                ( levelId :: "boards" :: "0" :: _, Just v ) ->
                    case Decode.decodeValue JsonUtils.boardDecoder v of
                        Ok board ->
                            ( model
                                |> LevelProgressUtils.setLevelProgressBoardHistoryInModel
                                    levelId
                                    (History.singleton board)
                            , Cmd.none
                            )

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )
