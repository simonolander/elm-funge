module Main exposing (main)

import Api.Auth0 as Auth0
import Api.GCP
import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.AuthorizationToken as AuthorizationToken exposing (AuthorizationToken)
import Data.Session as Session exposing (Session)
import Data.User as User exposing (User)
import Html
import Http
import Levels
import Page.Blueprint as Blueprint
import Page.Blueprints as Blueprints
import Page.Draft as Draft
import Page.Execution as Execution
import Page.Home as Home
import Page.Levels as Levels
import Page.Login as Login
import Route
import Set exposing (Set)
import Url exposing (Url)



-- MODEL


type alias Flags =
    ()


type Model
    = Home Home.Model
    | Levels Levels.Model
    | Execution Execution.Model
    | Draft Draft.Model
    | Blueprint Blueprint.Model
    | Blueprints Blueprints.Model
    | Login Login.Model



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
        levels =
            Levels.levels

        campaigns =
            List.map .campaignId levels
                |> Set.fromList
                |> Set.toList
                |> List.map
                    (\campaignId ->
                        { id = campaignId
                        , levelIds =
                            levels
                                |> List.filter (.campaignId >> (==) campaignId)
                                |> List.map .id
                        }
                    )

        sessionWithLevels =
            Session.init key
                |> Session.withLevels levels
                |> Session.withCampaigns campaigns

        ( sessionWithUser, sessionCmd ) =
            case Auth0.loginResponseFromUrl url of
                Just loginResponse ->
                    ( sessionWithLevels
                        |> Session.withUser (User.authorizedUser (AuthorizationToken.fromString loginResponse.accessToken))
                    , Api.GCP.verifyIdentityToken (AuthorizationToken.fromString loginResponse.accessToken) VerifyTokenResponse
                    )

                Nothing ->
                    ( sessionWithLevels
                    , Cmd.none
                    )

        ( model, pageCmd ) =
            changeUrl url sessionWithUser

        cmd =
            Cmd.batch
                [ pageCmd
                , sessionCmd
                ]
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
        Home mdl ->
            Home.view mdl

        Levels mdl ->
            Levels.view mdl
                |> msgMap LevelsMsg

        Execution mdl ->
            Execution.view mdl
                |> msgMap ExecutionMsg

        Draft mdl ->
            Draft.view mdl
                |> msgMap DraftMsg

        Blueprint mdl ->
            Blueprint.view mdl
                |> msgMap BlueprintMsg

        Blueprints mdl ->
            Blueprints.view mdl
                |> msgMap BlueprintsMsg

        Login mdl ->
            Login.view mdl
                |> msgMap LoginMsg



-- UPDATE


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | LevelsMsg Levels.Msg
    | ExecutionMsg Execution.Msg
    | DraftMsg Draft.Msg
    | HomeMsg Home.Msg
    | BlueprintsMsg Blueprints.Msg
    | BlueprintMsg Blueprint.Msg
    | LoginMsg Login.Msg
    | Ignored
    | VerifyTokenResponse (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            case model of
                Home mdl ->
                    Home.getSession mdl

                Levels mdl ->
                    Levels.getSession mdl

                Execution mdl ->
                    Execution.getSession mdl

                Draft mdl ->
                    Draft.getSession mdl

                Blueprints mdl ->
                    Blueprints.getSession mdl

                Blueprint mdl ->
                    Blueprint.getSession mdl

                Login mdl ->
                    Login.getSession mdl
    in
    case msg of
        Ignored ->
            ( model, Cmd.none )

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
            changeUrl url session

        VerifyTokenResponse response ->
            case response of
                Ok () ->
                    ( model, Cmd.none )

                Err error ->
                    ( model, Cmd.none )

        ExecutionMsg message ->
            case model of
                Execution mdl ->
                    Execution.update message mdl
                        |> updateWith Execution ExecutionMsg

                _ ->
                    ( model, Cmd.none )

        DraftMsg message ->
            case model of
                Draft mdl ->
                    Draft.update message mdl
                        |> updateWith Draft DraftMsg

                _ ->
                    ( model, Cmd.none )

        LevelsMsg message ->
            case model of
                Levels mdl ->
                    Levels.update message mdl
                        |> updateWith Levels LevelsMsg

                _ ->
                    ( model, Cmd.none )

        HomeMsg message ->
            case model of
                Home mdl ->
                    Home.update message mdl
                        |> updateWith Home HomeMsg

                _ ->
                    ( model, Cmd.none )

        BlueprintsMsg message ->
            case model of
                Blueprints mdl ->
                    Blueprints.update message mdl
                        |> updateWith Blueprints BlueprintsMsg

                _ ->
                    ( model, Cmd.none )

        BlueprintMsg message ->
            case model of
                Blueprint mdl ->
                    Blueprint.update message mdl
                        |> updateWith Blueprint BlueprintMsg

                _ ->
                    ( model, Cmd.none )

        LoginMsg message ->
            case model of
                Login mdl ->
                    Login.update message mdl
                        |> updateWith Login LoginMsg

                _ ->
                    ( model, Cmd.none )


updateWith : (a -> Model) -> (b -> Msg) -> ( a, Cmd b ) -> ( Model, Cmd Msg )
updateWith modelMap cmdMap ( model, cmd ) =
    ( modelMap model, Cmd.map cmdMap cmd )


changeUrl : Url.Url -> Session -> ( Model, Cmd Msg )
changeUrl url session =
    case Route.fromUrl url of
        Nothing ->
            Home.init session
                |> updateWith Home HomeMsg

        Just Route.Home ->
            Home.init session
                |> updateWith Home HomeMsg

        Just (Route.Campaign campaignId maybeLevelId) ->
            Levels.init campaignId maybeLevelId session
                |> updateWith Levels LevelsMsg

        Just (Route.EditDraft draftId) ->
            Draft.init draftId session
                |> updateWith Draft DraftMsg

        Just (Route.ExecuteDraft draftId) ->
            Execution.init draftId session
                |> updateWith Execution ExecutionMsg

        Just (Route.Blueprints maybeLevelId) ->
            Blueprints.init maybeLevelId session
                |> updateWith Blueprints BlueprintsMsg

        Just (Route.Blueprint levelId) ->
            Blueprint.init levelId session
                |> updateWith Blueprint BlueprintMsg

        Just Route.Login ->
            Login.init session
                |> updateWith Login LoginMsg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Home _ ->
            Sub.none

        Levels mdl ->
            Sub.map LevelsMsg (Levels.subscriptions mdl)

        Execution mdl ->
            Sub.map ExecutionMsg (Execution.subscriptions mdl)

        Draft mdl ->
            Sub.map DraftMsg (Draft.subscriptions mdl)

        Blueprints mdl ->
            Sub.map BlueprintsMsg (Blueprints.subscriptions mdl)

        Blueprint mdl ->
            Sub.map BlueprintMsg (Blueprint.subscriptions mdl)

        Login mdl ->
            Sub.map LoginMsg (Login.subscriptions mdl)
