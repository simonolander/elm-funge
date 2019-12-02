module Page.Blueprint.Update exposing (load, update)

import Array
import Array.Extra
import Basics.Extra exposing (flip)
import Data.Blueprint as Blueprint
import Data.Board as Board
import Data.CmdUpdater as CmdUpdater exposing (CmdUpdater, withModel)
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool as InstructionTool exposing (InstructionTool(..))
import Data.Int16 as Int16
import Data.Level as Level
import Data.Session as Session exposing (Session, updateBlueprints)
import Data.Suite as Suite
import Extra.Array
import List.Extra
import Maybe.Extra
import Page.Blueprint.Model exposing (Model)
import Page.Blueprint.Msg exposing (Msg(..))
import RemoteData
import Resource.Blueprint.Update exposing (getBlueprintByBlueprintId, loadBlueprintByBlueprintId, saveBlueprint)
import Update.SessionMsg exposing (SessionMsg)


load : CmdUpdater ( Session, Model ) SessionMsg
load =
    let
        loadBlueprint ( session, model ) =
            loadBlueprintByBlueprintId model.blueprintId session
                |> withModel model

        initializeInputsFromBlueprint ( session, model ) =
            let
                isNewBlueprint =
                    Maybe.map ((/=) model.blueprintId) model.loadedBlueprintId
                        |> Maybe.withDefault True

                maybeBlueprint =
                    getBlueprintByBlueprintId model.blueprintId session
                        |> RemoteData.toMaybe
                        |> Maybe.Extra.join
            in
            case ( isNewBlueprint, maybeBlueprint ) of
                ( True, Just blueprint ) ->
                    let
                        isNewBlueprint =
                            Maybe.map ((==) blueprint.id) model.loadedBlueprintId
                                |> Maybe.withDefault True

                        newModel =
                            if isNewBlueprint then
                                { model
                                    | blueprintId = blueprint.id
                                    , loadedBlueprintId = Just blueprint.id
                                    , width = String.fromInt (Board.width blueprint.initialBoard)
                                    , height = String.fromInt (Board.height blueprint.initialBoard)
                                    , input =
                                        blueprint.suites
                                            |> List.head
                                            |> Maybe.withDefault Suite.empty
                                            |> .input
                                            |> List.map Int16.toString
                                            |> String.join ","
                                    , output =
                                        blueprint.suites
                                            |> List.head
                                            |> Maybe.withDefault Suite.empty
                                            |> .output
                                            |> List.map Int16.toString
                                            |> String.join ","
                                    , enabledInstructionTools =
                                        InstructionTool.all
                                            |> List.filter ((/=) (JustInstruction NoOp))
                                            |> List.map (\tool -> ( tool, Extra.Array.member tool blueprint.instructionTools ))
                                            |> Array.fromList
                                }

                            else
                                model
                    in
                    ( ( session, newModel ), Cmd.none )

                _ ->
                    ( ( session, model ), Cmd.none )
    in
    CmdUpdater.batch
        [ loadBlueprint
        , initializeInputsFromBlueprint
        ]


update : Msg -> CmdUpdater ( Session, Model ) SessionMsg
update msg ( session, model ) =
    case
        getBlueprintByBlueprintId model.blueprintId session
            |> RemoteData.toMaybe
            |> Maybe.Extra.join
    of
        Just blueprint ->
            case msg of
                ChangedWidth widthString ->
                    CmdUpdater.withModel { model | width = widthString } <|
                        case
                            String.toInt widthString
                                |> Maybe.Extra.filter ((<=) Level.constraints.minWidth)
                                |> Maybe.Extra.filter ((>=) Level.constraints.maxWidth)
                        of
                            Just width ->
                                Blueprint.updateInitialBoard (Board.withWidth width) blueprint
                                    |> flip saveBlueprint session

                            Nothing ->
                                ( session, Cmd.none )

                ChangedHeight heightString ->
                    CmdUpdater.withModel { model | height = heightString } <|
                        case
                            String.toInt heightString
                                |> Maybe.Extra.filter ((<=) Level.constraints.minHeight)
                                |> Maybe.Extra.filter ((>=) Level.constraints.maxHeight)
                        of
                            Just height ->
                                Blueprint.updateInitialBoard (Board.withHeight height) blueprint
                                    |> flip saveBlueprint session

                            Nothing ->
                                ( session, Cmd.none )

                -- TODO Support for multiple suites
                ChangedInput inputString ->
                    String.split "," inputString
                        |> List.map String.trim
                        |> List.filterMap Int16.fromString
                        |> Suite.withInput
                        |> List.Extra.updateAt 0
                        |> flip Blueprint.updateSuites blueprint
                        |> flip saveBlueprint session
                        |> CmdUpdater.withModel { model | input = inputString }

                -- TODO Support for multiple suites
                ChangedOutput outputString ->
                    String.split "," outputString
                        |> List.map String.trim
                        |> List.filterMap Int16.fromString
                        |> Suite.withOutput
                        |> List.Extra.updateAt 0
                        |> flip Blueprint.updateSuites blueprint
                        |> flip saveBlueprint session
                        |> CmdUpdater.withModel { model | output = outputString }

                InstructionToolSelected index ->
                    ( ( session
                      , { model | selectedInstructionToolIndex = Just index }
                      )
                    , Cmd.none
                    )

                InstructionToolReplaced index instructionTool ->
                    ( ( session
                      , { model | instructionTools = Array.set index instructionTool model.instructionTools }
                      )
                    , Cmd.none
                    )

                InstructionToolEnabled index ->
                    let
                        newEnabledInstructionTools =
                            Array.Extra.update index (Tuple.mapSecond not) model.enabledInstructionTools
                    in
                    Array.filter Tuple.second newEnabledInstructionTools
                        |> Array.map Tuple.first
                        |> Array.append (Array.fromList [ JustInstruction NoOp ])
                        |> flip Blueprint.withInstructionTools blueprint
                        |> flip saveBlueprint session
                        |> CmdUpdater.withModel { model | enabledInstructionTools = newEnabledInstructionTools }

                InitialInstructionPlaced boardInstruction ->
                    Blueprint.updateInitialBoard (Board.withBoardInstruction boardInstruction) blueprint
                        |> flip saveBlueprint session
                        |> withModel model

        Nothing ->
            ( ( session, model ), Cmd.none )
