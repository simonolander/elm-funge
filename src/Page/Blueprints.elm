module Page.Blueprints exposing (Model, Msg(..), init, load, subscriptions, update, view)

import ApplicationName exposing (applicationName)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Data.Blueprint as Blueprint exposing (Blueprint)
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache
import Data.Campaign as Campaign exposing (Campaign)
import Data.GetError as GetError exposing (GetError(..))
import Data.Session as Session exposing (Session, withSession)
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Extra.Cmd exposing (withExtraCmd)
import Html exposing (Html)
import Maybe.Extra
import Ports.Console as Console
import Random
import RemoteData exposing (RemoteData(..))
import Route
import SessionUpdate exposing (SessionMsg(..))
import String.Extra
import Update.Blueprint
import View.Constant exposing (size)
import View.ErrorScreen
import View.Layout
import View.LoadingScreen
import View.SingleSidebar
import ViewComponents



-- MODEL


type Modal
    = ConfirmDelete BlueprintId


type alias Model =
    { session : Session
    , selectedBlueprintId : Maybe BlueprintId
    , modal : Maybe Modal
    }


type Msg
    = InternalMsg InternalMsg
    | SessionMsg SessionMsg


type InternalMsg
    = BlueprintGenerated Blueprint
    | SelectedBlueprintId BlueprintId
    | BlueprintNameChanged String
    | BlueprintDescriptionChanged String
    | ClickedNewBlueprint
    | ClickedDeleteBlueprint BlueprintId
    | ClickedConfirmDeleteBlueprint
    | ClickedCancelDeleteBlueprint


init : Maybe BlueprintId -> Session -> ( Model, Cmd Msg )
init selectedBlueprintId session =
    let
        model =
            { session = session
            , selectedBlueprintId = selectedBlueprintId
            , modal = Nothing
            }
    in
    ( model, Cmd.none )


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadBlueprints model =
            Update.Blueprint.loadBlueprints model.session
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)
    in
    Extra.Cmd.fold
        [ loadBlueprints ]


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }



-- UPDATE


update : InternalMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedConfirmDeleteBlueprint ->
            case model.modal of
                Just (ConfirmDelete blueprintId) ->
                    Update.Blueprint.deleteBlueprint blueprintId model.session
                        |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

                Nothing ->
                    ( model, Cmd.none )

        ClickedDeleteBlueprint blueprintId ->
            ( { model | modal = Just (ConfirmDelete blueprintId) }, Cmd.none )

        ClickedCancelDeleteBlueprint ->
            case model.modal of
                Just (ConfirmDelete _) ->
                    ( { model | modal = Nothing }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        BlueprintNameChanged newName ->
            case
                Maybe.map (flip Cache.get model.session.blueprints.local) model.selectedBlueprintId
                    |> Maybe.andThen RemoteData.toMaybe
                    |> Maybe.andThen Maybe.Extra.join
            of
                Just blueprint ->
                    Update.Blueprint.saveBlueprint { blueprint | name = newName } model.session
                        |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

                Nothing ->
                    ( model, Console.errorString "tWy71t5l    Could not update blueprint name" )

        BlueprintDescriptionChanged newDescription ->
            case
                Maybe.map (flip Cache.get model.session.blueprints.local) model.selectedBlueprintId
                    |> Maybe.andThen RemoteData.toMaybe
                    |> Maybe.andThen Maybe.Extra.join
            of
                Just blueprint ->
                    Update.Blueprint.saveBlueprint { blueprint | description = String.lines newDescription } model.session
                        |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)

                Nothing ->
                    ( model, Console.errorString "Pm6iHnXM    Could not update blueprint description" )

        SelectedBlueprintId blueprintId ->
            ( { model | selectedBlueprintId = Just blueprintId }
            , Route.replaceUrl model.session.key (Route.Blueprints (Just blueprintId))
            )

        ClickedNewBlueprint ->
            ( model, Random.generate (InternalMsg << BlueprintGenerated) Blueprint.generator )

        BlueprintGenerated blueprint ->
            Update.Blueprint.saveBlueprint blueprint
                |> Tuple.mapBoth (flip withSession model) (Cmd.map SessionMsg)
                |> Tuple.mapFirst (withSelectedBlueprintId blueprint.id)
                |> withExtraCmd (Route.replaceUrl model.session.key (Route.Blueprints (Just blueprint.id)))



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions =
    always Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        session =
            model.session

        content =
            case Session.getCampaign campaignId session of
                NotAsked ->
                    View.ErrorScreen.layout "Not asked :/"

                Loading ->
                    View.LoadingScreen.layout ("Loading " ++ campaignId)

                Failure error ->
                    View.ErrorScreen.layout (GetError.toString error)

                Success campaign ->
                    viewCampaign campaign model
                        |> View.Layout.layout
                        |> Html.map InternalMsg
    in
    { body = [ content ]
    , title = String.concat [ "Blueprints", " - ", applicationName ]
    }


viewCampaign : Campaign -> Model -> Element InternalMsg
viewCampaign campaign model =
    let
        session =
            model.session

        sidebarContent =
            case
                model.selectedBlueprintId
                    |> Maybe.map (flip Session.getBlueprint session)
                    |> Maybe.andThen RemoteData.toMaybe
            of
                Just blueprint ->
                    let
                        blueprintName =
                            Input.text
                                [ Background.color (rgb 0.1 0.1 0.1) ]
                                { onChange = BlueprintNameChanged
                                , text = blueprint.name
                                , placeholder = Nothing
                                , label =
                                    Input.labelAbove
                                        []
                                        (text "Blueprint name")
                                }

                        blueprintDescription =
                            Input.multiline
                                [ Background.color (rgb 0.1 0.1 0.1)
                                , height (minimum 200 shrink)
                                ]
                                { onChange = BlueprintDescriptionChanged
                                , text = String.join "\n" blueprint.description
                                , placeholder = Nothing
                                , label =
                                    Input.labelAbove
                                        []
                                        (text "Blueprint description")
                                , spellcheck = True
                                }

                        openBlueprint =
                            Route.link
                                [ width fill ]
                                (ViewComponents.textButton [] Nothing "Open")
                                (Route.Blueprint blueprint.id)

                        deleteBlueprint =
                            ViewComponents.textButton
                                []
                                (Just (ClickedDeleteBlueprint blueprint.id))
                                "Delete"
                    in
                    [ blueprintName
                    , blueprintDescription
                    , openBlueprint
                    , deleteBlueprint
                    ]

                Nothing ->
                    [ el [ centerX, size.font.sidebar.title ] (text "Blueprints")
                    , paragraph [ Font.center ] [ text "Here you can make your own blueprints. A blueprint is a blueprint that is not yet published. Once you publish a blueprint, you cannot change it." ]
                    ]

        mainContent =
            let
                default =
                    View.BlueprintButton.default

                plusButton =
                    ViewComponents.textButton [] (Just ClickedNewBlueprint) "Create new blueprint"

                blueprintButton blueprintId =
                    case
                        Session.getBlueprint blueprintId session
                            |> RemoteData.toMaybe
                    of
                        Just blueprint ->
                            View.BlueprintButton.view
                                { default
                                    | onPress = Just (SelectedBlueprintId blueprintId)
                                    , selected =
                                        model.selectedBlueprintId
                                            |> Maybe.map ((==) blueprintId)
                                            |> Maybe.withDefault False
                                }
                                blueprint

                        -- TODO Maybe different cases for loading, error and not asked?
                        Nothing ->
                            View.BlueprintButton.loading blueprintId

                blueprintButtons =
                    List.map blueprintButton campaign.blueprintIds
            in
            column
                [ width fill, spacing 30 ]
                [ plusButton
                , wrappedRow
                    [ spacing 20
                    ]
                    blueprintButtons
                ]

        modal =
            Maybe.map (flip viewModal model) model.modal
    in
    View.SingleSidebar.view
        { sidebar = sidebarContent
        , main = mainContent
        , session = model.session
        , modal = modal
        }


viewModal : Modal -> Model -> Element InternalMsg
viewModal modal model =
    case modal of
        ConfirmDelete blueprintId ->
            let
                blueprintName =
                    Cache.get blueprintId model.session.blueprints.local
                        |> RemoteData.toMaybe
                        |> Maybe.Extra.join
                        |> Maybe.map .name
                        |> Maybe.map String.trim
                        |> Maybe.andThen String.Extra.nonEmpty
                        |> Maybe.withDefault "no name"
            in
            column
                []
                [ paragraph [ Font.center ]
                    [ text "Do you really want to delete blueprint "
                    , text blueprintName
                    , text " ("
                    , text blueprintId
                    , text ")"
                    , text "?"
                    ]
                , ViewComponents.textButton [] (Just ClickedConfirmDeleteBlueprint) "Delete"
                , ViewComponents.textButton [] (Just ClickedCancelDeleteBlueprint) "Cancel"
                ]
