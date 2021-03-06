module Page.Blueprint exposing (Model, Msg, getSession, init, load, subscriptions, update, view)

import ApplicationName exposing (applicationName)
import Array exposing (Array)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Board as Board
import Data.BoardInstruction as BoardInstruction exposing (BoardInstruction)
import Data.CampaignId as CampaignId
import Data.GetError as GetError
import Data.Instruction exposing (Instruction(..))
import Data.InstructionTool as InstructionTool exposing (InstructionTool(..))
import Data.Int16 as Int16
import Data.Level as Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.Session as Session exposing (Session)
import Data.Suite as Suite
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Extra.Array
import Extra.Cmd exposing (noCmd)
import InstructionToolView
import Maybe.Extra
import RemoteData exposing (RemoteData(..))
import Route
import View.Board
import View.ErrorScreen
import View.Header
import View.Input
import View.InstructionTools
import View.Layout
import View.LoadingScreen
import View.Scewn
import ViewComponents



-- MODEL


type alias Model =
    { session : Session
    , levelId : LevelId
    , loadedLevelId : Maybe LevelId
    , width : String
    , height : String
    , input : String
    , output : String
    , error : Maybe String
    , instructionTools : Array InstructionTool
    , selectedInstructionToolIndex : Maybe Int
    , enabledInstructionTools : Array ( InstructionTool, Bool )
    }


init : LevelId -> Session -> ( Model, Cmd Msg )
init levelId session =
    let
        model =
            { session = session
            , levelId = levelId
            , loadedLevelId = Nothing
            , width = ""
            , height = ""
            , input = ""
            , output = ""
            , error = Nothing
            , instructionTools = Array.fromList InstructionTool.all
            , selectedInstructionToolIndex = Nothing
            , enabledInstructionTools = Array.empty
            }
    in
    ( model, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadLevel model =
            case Session.getLevel model.levelId model.session of
                NotAsked ->
                    ( model.session
                        |> Session.levelLoading model.levelId
                        |> setSession model
                    , Level.loadFromLocalStorage model.levelId
                    )

                Success level ->
                    if
                        model.loadedLevelId
                            |> Maybe.map ((==) level.id)
                            |> Maybe.withDefault False
                    then
                        noCmd model

                    else
                        ( { model
                            | levelId = level.id
                            , loadedLevelId = Just level.id
                            , width = String.fromInt (Board.width level.initialBoard)
                            , height = String.fromInt (Board.height level.initialBoard)
                            , input =
                                level.suites
                                    |> List.head
                                    |> Maybe.withDefault Suite.empty
                                    |> .input
                                    |> List.map Int16.toString
                                    |> String.join ","
                            , output =
                                level.suites
                                    |> List.head
                                    |> Maybe.withDefault Suite.empty
                                    |> .output
                                    |> List.map Int16.toString
                                    |> String.join ","
                            , enabledInstructionTools =
                                InstructionTool.all
                                    |> List.filter ((/=) (JustInstruction NoOp))
                                    |> List.map (\tool -> ( tool, Extra.Array.member tool level.instructionTools ))
                                    |> Array.fromList
                          }
                        , Cmd.none
                        )

                _ ->
                    noCmd model
    in
    Extra.Cmd.fold
        [ loadLevel ]


initWithLevel : Level -> Model -> ( Model, Cmd Msg )
initWithLevel level model =
    ( { model
        | levelId = level.id
        , width = String.fromInt (Board.width level.initialBoard)
        , height = String.fromInt (Board.height level.initialBoard)
        , input =
            level.suites
                |> List.head
                |> Maybe.withDefault Suite.empty
                |> .input
                |> List.map Int16.toString
                |> String.join ","
        , output =
            level.suites
                |> List.head
                |> Maybe.withDefault Suite.empty
                |> .output
                |> List.map Int16.toString
                |> String.join ","
        , enabledInstructionTools =
            InstructionTool.all
                |> List.filter ((/=) (JustInstruction NoOp))
                |> List.map (\tool -> ( tool, Extra.Array.member tool level.instructionTools ))
                |> Array.fromList
      }
    , Cmd.none
    )


getSession : Model -> Session
getSession { session } =
    session


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }



-- UPDATE


type Msg
    = ChangedWidth String
    | ChangedHeight String
    | ChangedInput String
    | ChangedOutput String
    | InstructionToolSelected Int
    | InstructionToolReplaced Int InstructionTool
    | InstructionToolEnabled Int
    | InitialInstructionPlaced BoardInstruction


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case
        Session.getLevel model.levelId model.session
            |> RemoteData.toMaybe
    of
        Just level ->
            case msg of
                ChangedWidth widthString ->
                    let
                        modelWithWidth =
                            { model | width = widthString }
                    in
                    case String.toInt widthString of
                        Just width ->
                            if width < Level.constraints.minWidth then
                                ( modelWithWidth, Cmd.none )

                            else if width > Level.constraints.maxWidth then
                                ( modelWithWidth, Cmd.none )

                            else
                                let
                                    newLevel =
                                        level.initialBoard
                                            |> Board.withWidth width
                                            |> flip Level.withInitialBoard level

                                    session =
                                        Session.withLevel newLevel model.session

                                    cmd =
                                        Level.saveToLocalStorage newLevel
                                in
                                ( { modelWithWidth | session = session }, cmd )

                        Nothing ->
                            ( modelWithWidth, Cmd.none )

                ChangedHeight heightString ->
                    let
                        modelWithHeight =
                            { model | height = heightString }
                    in
                    case String.toInt heightString of
                        Just height ->
                            if height < Level.constraints.minHeight then
                                ( modelWithHeight, Cmd.none )

                            else if height > Level.constraints.maxHeight then
                                ( modelWithHeight, Cmd.none )

                            else
                                let
                                    newLevel =
                                        level.initialBoard
                                            |> Board.withHeight height
                                            |> flip Level.withInitialBoard level

                                    session =
                                        Session.withLevel newLevel model.session

                                    cmd =
                                        Level.saveToLocalStorage newLevel
                                in
                                ( { modelWithHeight | session = session }, cmd )

                        Nothing ->
                            ( modelWithHeight, Cmd.none )

                ChangedInput inputString ->
                    let
                        modelWithInput =
                            { model | input = inputString }

                        input =
                            inputString
                                |> String.split ","
                                |> List.map String.trim
                                |> List.map Int16.fromString
                                |> Maybe.Extra.values

                        suite =
                            level.suites
                                |> List.head
                                |> Maybe.withDefault Suite.empty
                                |> Suite.withInput input

                        newLevel =
                            Level.withSuites [ suite ] level

                        newSession =
                            Session.withLevel newLevel model.session

                        cmd =
                            Level.saveToLocalStorage newLevel
                    in
                    ( { modelWithInput | session = newSession }, cmd )

                ChangedOutput outputString ->
                    let
                        modelWithOutput =
                            { model | output = outputString }

                        output =
                            outputString
                                |> String.split ","
                                |> List.map String.trim
                                |> List.map Int16.fromString
                                |> Maybe.Extra.values

                        suite =
                            level.suites
                                |> List.head
                                |> Maybe.withDefault Suite.empty
                                |> Suite.withOutput output

                        newLevel =
                            Level.withSuites [ suite ] level

                        newSession =
                            Session.withLevel newLevel model.session

                        cmd =
                            Level.saveToLocalStorage newLevel
                    in
                    ( { modelWithOutput | session = newSession }, cmd )

                InstructionToolSelected index ->
                    ( { model | selectedInstructionToolIndex = Just index }, Cmd.none )

                InstructionToolReplaced index instructionTool ->
                    ( { model | instructionTools = Array.set index instructionTool model.instructionTools }, Cmd.none )

                InstructionToolEnabled index ->
                    let
                        newEnabledInstructionTools =
                            Array.get index model.enabledInstructionTools
                                |> Maybe.map (\( tool, enabled ) -> ( tool, not enabled ))
                                |> Maybe.map (flip (Array.set index) model.enabledInstructionTools)
                                |> Maybe.withDefault model.enabledInstructionTools

                        newLevel =
                            newEnabledInstructionTools
                                |> Array.filter Tuple.second
                                |> Array.map Tuple.first
                                |> Array.append (Array.fromList [ JustInstruction NoOp ])
                                |> flip Level.withInstructionTools level

                        newSession =
                            Session.withLevel newLevel model.session

                        cmd =
                            Level.saveToLocalStorage newLevel
                    in
                    ( { model
                        | session = newSession
                        , enabledInstructionTools = newEnabledInstructionTools
                      }
                    , cmd
                    )

                InitialInstructionPlaced boardInstruction ->
                    let
                        newLevel =
                            boardInstruction
                                |> flip Board.withBoardInstruction level.initialBoard
                                |> flip Level.withInitialBoard level

                        newModel =
                            newLevel
                                |> flip Session.withLevel model.session
                                |> setSession model

                        cmd =
                            Level.saveToLocalStorage newLevel
                    in
                    ( newModel, cmd )

        Nothing ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        content =
            case Session.getLevel model.levelId model.session of
                NotAsked ->
                    View.ErrorScreen.view "Not asked :/"

                Loading ->
                    View.LoadingScreen.view ("Loading level " ++ model.levelId)

                Failure error ->
                    View.ErrorScreen.view (GetError.toString error)

                Success level ->
                    viewBlueprint level model

        body =
            content
                |> View.Layout.layout
                |> List.singleton
    in
    { body = body
    , title = String.concat [ "Blueprint", " - ", applicationName ]
    }


viewBlueprint : Level -> Model -> Element Msg
viewBlueprint level model =
    let
        header =
            View.Header.view model.session

        west =
            let
                widthInput =
                    View.Input.numericInput []
                        { text = model.width
                        , labelText = "Width"
                        , onChange = ChangedWidth
                        , placeholder = Nothing
                        , min = Just Level.constraints.minWidth
                        , max = Just Level.constraints.maxWidth
                        , step = Just 1
                        }

                heightInput =
                    View.Input.numericInput []
                        { text = model.height
                        , labelText = "Height"
                        , onChange = ChangedHeight
                        , placeholder = Nothing
                        , min = Just Level.constraints.minHeight
                        , max = Just Level.constraints.maxHeight
                        , step = Just 1
                        }

                inputInput =
                    View.Input.textInput
                        []
                        { onChange = ChangedInput
                        , text = model.input
                        , labelText = "Input"
                        , placeholder = Just "1,2,3,0"
                        }

                outputInput =
                    View.Input.textInput
                        []
                        { onChange = ChangedOutput
                        , text = model.output
                        , labelText = "Output"
                        , placeholder = Just "2,4,6"
                        }

                instructionTools =
                    let
                        enableInstructionToolButton index ( tool, enabled ) =
                            ViewComponents.imageButton
                                [ if enabled then
                                    Background.color (rgb 0.25 0.25 0.25)

                                  else
                                    Background.color (rgb 0 0 0)
                                ]
                                (Just (InstructionToolEnabled index))
                                (InstructionToolView.view [] tool)

                        instructionToolRow =
                            model.enabledInstructionTools
                                |> Array.indexedMap enableInstructionToolButton
                                |> Array.toList
                                |> wrappedRow [ spacing 10 ]

                        title =
                            text "Enabled instructions"
                    in
                    column
                        [ width fill
                        ]
                        [ title
                        , instructionToolRow
                        ]

                link =
                    Route.link [] (text "test") (Route.Campaign CampaignId.blueprints (Just level.id))
            in
            column
                [ width fill
                , height fill
                , padding 20
                , spacing 20
                , scrollbars
                , Background.color (rgb 0.05 0.05 0.05)
                ]
                [ paragraph
                    [ width fill
                    , Font.center
                    ]
                    [ text level.name ]
                , widthInput
                , heightInput
                , inputInput
                , outputInput
                , instructionTools
                , link
                ]

        center =
            let
                board =
                    level.initialBoard

                onClick : Maybe (BoardInstruction -> Msg)
                onClick =
                    model.selectedInstructionToolIndex
                        |> Maybe.andThen (flip Array.get model.instructionTools)
                        |> Maybe.map InstructionTool.getInstruction
                        |> Maybe.map BoardInstruction.withInstruction
                        |> Maybe.map ((<<) InitialInstructionPlaced)

                selectedPosition =
                    Nothing

                disabledPositions =
                    []
            in
            View.Board.view
                { board = board
                , onClick = onClick
                , selectedPosition = selectedPosition
                , disabledPositions = disabledPositions
                }

        east =
            View.InstructionTools.view
                { instructionTools = model.instructionTools
                , selectedIndex = model.selectedInstructionToolIndex
                , onSelect = Just InstructionToolSelected
                , onReplace = InstructionToolReplaced
                }
    in
    View.Scewn.view
        { north = Just header
        , west = Just west
        , center = Just center
        , east = Just east
        , south = Nothing
        , modal = Nothing
        }
