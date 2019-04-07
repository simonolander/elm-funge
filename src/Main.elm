module Main exposing (main)

--import LocalStorage

import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.AuthorizationToken as AuthorizationToken exposing (AuthorizationToken)
import Data.User as User exposing (User)
import Html
import Maybe.Extra
import Page.Draft as Draft
import Page.Execution as Execution
import Page.Home as Home
import Page.Levels as Levels
import RemoteData
import Route
import Url exposing (Url)



-- MODEL


type alias Flags =
    ()


type Model
    = Home Home.Model
    | Levels Levels.Model
    | Execution Execution.Model
    | Draft Draft.Model



-- MAIN


main : Program Flags Model Msg
main =
    Browser.application
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        }



-- INIT


init : Flags -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        user =
            url.fragment
                |> Maybe.withDefault ""
                |> String.split "&"
                |> List.map
                    (\pair ->
                        case String.split "=" pair of
                            [ queryKey, value ] ->
                                Just ( queryKey, value )

                            _ ->
                                Nothing
                    )
                |> Maybe.Extra.values
                |> List.filter (Tuple.first >> (==) "id_token")
                |> List.head
                |> Maybe.map Tuple.second
                |> Maybe.map AuthorizationToken.fromString
                |> Maybe.map User.authorizedUser
                |> Maybe.withDefault User.guest

        model : Model
        model =
            Home
                { session =
                    { key = key
                    , user = user
                    }
                }

        cmd : Cmd Msg
        cmd =
            Cmd.none
    in
    ( model, cmd )



-- VIEW


view : Model -> Document Msg
view model =
    let
        msgMap : (a -> Msg) -> Document a -> Document Msg
        msgMap function document =
            { title = document.title
            , body =
                document.body
                    |> List.map (Html.map function)
            }
    in
    case model of
        Home homeModel ->
            Home.view homeModel

        Levels levelsModel ->
            Levels.view levelsModel
                |> msgMap LevelsMsg

        Execution executionModel ->
            Execution.view executionModel
                |> msgMap ExecutionMsg

        Draft draftModel ->
            Draft.view draftModel
                |> msgMap DraftMsg



-- UPDATE


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | LevelsMsg Levels.Msg
    | ExecutionMsg Execution.Msg
    | DraftMsg Draft.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            case model of
                Home homeModel ->
                    homeModel.session

                Levels levelsModel ->
                    levelsModel.session

                Execution executionModel ->
                    executionModel.session

                Draft draftModel ->
                    draftModel.session
    in
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    case url.fragment of
                        Nothing ->
                            ( model, Cmd.none )

                        Just _ ->
                            ( model
                            , Navigation.pushUrl session.key (Url.toString url)
                            )

                Browser.External href ->
                    ( model
                    , Navigation.load href
                    )

        ChangedUrl url ->
            case Route.fromUrl url of
                Nothing ->
                    ( model, Cmd.none )

                Just Route.Home ->
                    ( Home { session = session }, Cmd.none )

                Just Route.Levels ->
                    Levels.init session
                        |> updateWith Levels LevelsMsg

                Just (Route.EditDraft draftId) ->
                    ( Levels
                        { session = session
                        , levels = RemoteData.NotAsked
                        , selectedLevel = Nothing
                        }
                    , Cmd.none
                    )

                Just (Route.ExecuteDraft draftId) ->
                    ( Levels
                        { session = session
                        , levels = RemoteData.NotAsked
                        , selectedLevel = Nothing
                        }
                    , Cmd.none
                    )

        ExecutionMsg executionMsg ->
            case model of
                Execution executionModel ->
                    Execution.update executionMsg executionModel
                        |> updateWith Execution ExecutionMsg

                _ ->
                    ( model, Cmd.none )

        DraftMsg draftMsg ->
            case model of
                Draft draftModel ->
                    Draft.update draftMsg draftModel
                        |> updateWith Draft DraftMsg

                _ ->
                    ( model, Cmd.none )

        LevelsMsg levelsMsg ->
            case model of
                Levels levelsModel ->
                    Levels.update levelsMsg levelsModel
                        |> updateWith Levels LevelsMsg

                _ ->
                    ( model, Cmd.none )


updateWith : (a -> Model) -> (b -> Msg) -> ( a, Cmd b ) -> ( Model, Cmd Msg )
updateWith modelMap cmdMap ( model, cmd ) =
    ( modelMap model, Cmd.map cmdMap cmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Home _ ->
            Sub.none

        Levels _ ->
            Sub.none

        Execution m ->
            Sub.map ExecutionMsg (Execution.subscriptions m)

        Draft _ ->
            Sub.map DraftMsg Draft.subscriptions
