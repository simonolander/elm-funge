module Main exposing (main)

import Api.Auth0 as Auth0
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.Cache as Cache
import Data.Campaign
import Data.Draft
import Data.DraftBook
import Data.GetError as GetError exposing (GetError(..))
import Data.Level
import Data.RemoteCache as RemoteCache
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.Session as Session exposing (Session)
import Data.Solution
import Data.SolutionBook
import Extra.Cmd exposing (withExtraCmd)
import Html
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Page.Blueprint as Blueprint
import Page.Blueprints as Blueprints
import Page.Campaign as Campaign
import Page.Draft as Draft
import Page.Execution as Execution
import Page.Home as Home
import Page.Initialize as Initialize
import Ports.Console
import Ports.LocalStorage
import Route
import SessionUpdate
import Url exposing (Url)



-- MODEL


type alias Flags =
    { width : Int
    , height : Int
    , currentTimeMillis : Int
    , localStorageEntries : List ( String, Encode.Value )
    }


type Model
    = Home Home.Model
    | Campaign Campaign.Model
    | Execution Execution.Model
    | Draft Draft.Model
    | Blueprint Blueprint.Model
    | Blueprints Blueprints.Model
    | Initialize Initialize.Model



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
    { navigationKey = key
    , url = url
    , localStorageEntries = flags.localStorageEntries
    }
        |> Initialize.init
        |> updateWith Initialize InitializeMsg
        |> load



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

        Campaign mdl ->
            Campaign.view mdl
                |> msgMap CampaignMsg

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

        Initialize mdl ->
            Initialize.view mdl
                |> msgMap InitializeMsg



-- UPDATE


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | CampaignMsg Campaign.Msg
    | ExecutionMsg Execution.Msg
    | DraftMsg Draft.Msg
    | HomeMsg Home.Msg
    | BlueprintsMsg Blueprints.Msg
    | BlueprintMsg Blueprint.Msg
    | InitializeMsg Initialize.Msg
    | LocalStorageResponse ( String, Encode.Value )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    load <|
        case ( msg, model ) of
            ( ClickedLink urlRequest, _ ) ->
                case urlRequest of
                    Browser.Internal url ->
                        case url.fragment of
                            Nothing ->
                                ( model, Cmd.none )

                            Just _ ->
                                ( model
                                , Navigation.pushUrl (getSession model).key (Url.toString url)
                                )

                    Browser.External href ->
                        let
                            cmd =
                                [ if href == Auth0.logout then
                                    Just (Ports.LocalStorage.storageClear ())

                                  else
                                    Nothing
                                , Just (Navigation.load href)
                                ]
                                    |> Maybe.Extra.values
                                    |> Cmd.batch
                        in
                        ( model
                        , cmd
                        )

            ( ChangedUrl url, _ ) ->
                changeUrl url (getSession model)

            ( LocalStorageResponse response, mdl ) ->
                localStorageResponseUpdate response mdl

            ( ExecutionMsg (Execution.InternalMsg message), Execution mdl ) ->
                Execution.update message mdl
                    |> updateWith Execution ExecutionMsg

            ( ExecutionMsg (Execution.SessionMsg message), mdl ) ->
                mdl
                    |> getSession
                    |> SessionUpdate.update message
                    |> updateWith (flip withSession mdl) ExecutionMsg

            ( DraftMsg message, Draft mdl ) ->
                Draft.update message mdl
                    |> updateWith Draft DraftMsg

            ( DraftMsg (Draft.SessionMsg message), mdl ) ->
                mdl
                    |> getSession
                    |> SessionUpdate.update message
                    |> updateWith (flip withSession mdl) DraftMsg

            ( CampaignMsg message, Campaign mdl ) ->
                Campaign.update message mdl
                    |> updateWith Campaign CampaignMsg

            ( CampaignMsg (Campaign.SessionMsg message), mdl ) ->
                mdl
                    |> getSession
                    |> SessionUpdate.update message
                    |> updateWith (flip withSession mdl) CampaignMsg

            ( HomeMsg message, Home mdl ) ->
                Home.update message mdl
                    |> updateWith Home HomeMsg

            ( BlueprintsMsg message, Blueprints mdl ) ->
                Blueprints.update message mdl
                    |> updateWith Blueprints BlueprintsMsg

            ( BlueprintMsg message, Blueprint mdl ) ->
                Blueprint.update message mdl
                    |> updateWith Blueprint BlueprintMsg

            ( InitializeMsg message, Initialize mdl ) ->
                Initialize.update message mdl
                    |> updateWith Initialize InitializeMsg

            ( message, mdl ) ->
                Debug.todo ("Wrong message for model: " ++ Debug.toString ( message, mdl ))


updateWith : (a -> Model) -> (b -> Msg) -> ( a, Cmd b ) -> ( Model, Cmd Msg )
updateWith modelMap cmdMap ( model, cmd ) =
    ( modelMap model, Cmd.map cmdMap cmd )


changeUrl : Url.Url -> Session -> ( Model, Cmd Msg )
changeUrl url oldSession =
    let
        session =
            Session.withUrl url oldSession
    in
    load <|
        case Route.fromUrl url of
            Nothing ->
                Home.init session
                    |> updateWith Home HomeMsg

            Just Route.Home ->
                Home.init session
                    |> updateWith Home HomeMsg

            Just (Route.Campaign campaignId maybeLevelId) ->
                Campaign.init campaignId maybeLevelId session
                    |> updateWith Campaign CampaignMsg

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


localStorageResponseUpdate : ( String, Encode.Value ) -> Model -> ( Model, Cmd Msg )
localStorageResponseUpdate response mainModel =
    let
        onSingle :
            { name : String
            , success : value -> Session -> Session
            , notFound : String -> Session -> Session
            , failure : String -> Decode.Error -> Session -> Session
            , transform : ( String, Encode.Value ) -> Maybe (RequestResult String Decode.Error (Maybe value))
            }
            -> ( { model | session : Session }, Cmd msg )
            -> ( { model | session : Session }, Cmd msg )
        onSingle { name, success, notFound, failure, transform } ( mdl, cmd ) =
            case transform response of
                Just { request, result } ->
                    case result of
                        Ok (Just campaign) ->
                            ( { mdl | session = success campaign mdl.session }
                            , cmd
                            )

                        Ok Nothing ->
                            let
                                errorMessage =
                                    name ++ " " ++ request ++ " not found"
                            in
                            ( { mdl | session = notFound request mdl.session }
                            , Cmd.batch [ cmd, Ports.Console.errorString errorMessage ]
                            )

                        Err error ->
                            ( { mdl | session = failure request error mdl.session }
                            , Cmd.batch [ cmd, Ports.Console.errorString (Decode.errorToString error) ]
                            )

                Nothing ->
                    ( mdl, cmd )

        onCollection :
            { success : value -> Session -> Session
            , failure : String -> GetError -> Session -> Session
            , transform : ( String, Encode.Value ) -> Maybe (RequestResult String Decode.Error value)
            }
            -> ( { model | session : Session }, Cmd msg )
            -> ( { model | session : Session }, Cmd msg )
        onCollection { transform, success, failure } ( mdl, cmd ) =
            case transform response of
                Just { request, result } ->
                    case result of
                        Ok collection ->
                            ( { mdl | session = success collection mdl.session }
                            , cmd
                            )

                        Err error ->
                            ( { mdl | session = failure request (RequestResult.badBody error) mdl.session }
                            , Cmd.batch [ cmd, Ports.Console.errorString (Decode.errorToString error) ]
                            )

                Nothing ->
                    ( mdl, cmd )

        onCampaign =
            onSingle
                { name = "Campaign"
                , success = Session.withCampaign
                , notFound = \id session -> Session.campaignError id (GetError.Other "Not found in local storage") session
                , failure =
                    \campaignId error session ->
                        session.campaigns
                            |> Cache.withError campaignId (GetError.Other (Decode.errorToString error))
                            |> flip Session.withCampaignCache session
                , transform = Data.Campaign.localStorageResponse
                }

        onLevel =
            onSingle
                { name = "Level"
                , success = Session.withLevel
                , notFound = \id session -> Session.levelError id (GetError.Other "Not found in local storage") session
                , failure =
                    \levelId error session ->
                        session.levels
                            |> Cache.withError levelId (GetError.Other (Decode.errorToString error))
                            |> flip Session.withLevelCache session
                , transform = Data.Level.localStorageResponse
                }

        onDraft =
            let
                notFound : String -> Session -> Session
                notFound =
                    \draftId session ->
                        session.drafts
                            |> RemoteCache.withLocalValue draftId Nothing
                            |> flip Session.withDraftCache session
            in
            onSingle
                { name = "Draft"
                , success =
                    \draft session ->
                        session.drafts
                            |> RemoteCache.withLocalValue draft.id (Just draft)
                            |> flip Session.withDraftCache session
                , notFound = notFound
                , failure =
                    \draftId error session ->
                        session.drafts
                            |> RemoteCache.withLocalResult draftId (Err error)
                            |> flip Session.withDraftCache session
                , transform = Data.Draft.localStorageResponse
                }

        onSolution =
            let
                notFound : String -> Session -> Session
                notFound =
                    \solutionId session ->
                        session.solutions
                            |> RemoteCache.withLocalValue solutionId Nothing
                            |> flip Session.withSolutionCache session
            in
            onSingle
                { name = "Solution"
                , success =
                    \solution session ->
                        session.solutions
                            |> RemoteCache.withLocalValue solution.id (Just solution)
                            |> flip Session.withSolutionCache session
                , notFound =
                    notFound
                , failure =
                    \solutionId error session ->
                        session.solutions
                            |> RemoteCache.withLocalResult solutionId (Err error)
                            |> flip Session.withSolutionCache session
                , transform = Data.Solution.localStorageResponse
                }

        onDraftBook =
            onCollection
                { success = Session.withDraftBook
                , failure = Session.draftBookError
                , transform = Data.DraftBook.localStorageResponse
                }

        onSolutionBook =
            onCollection
                { success = Session.withSolutionBook
                , failure = Session.solutionBookError
                , transform = Data.SolutionBook.localStorageResponse
                }

        onResponse : { model | session : Session } -> ( { model | session : Session }, Cmd msg )
        onResponse mdl =
            ( mdl, Cmd.none )
                |> onCampaign
                |> onLevel
                |> onDraft
                |> onDraftBook
                |> onSolutionBook
                |> onSolution
    in
    load <|
        case mainModel of
            Home model ->
                updateWith Home HomeMsg (onResponse model)

            Campaign model ->
                updateWith Campaign CampaignMsg (onResponse model)

            Execution model ->
                updateWith Execution ExecutionMsg (onResponse model)

            Draft model ->
                updateWith Draft DraftMsg (onResponse model)

            Blueprints model ->
                updateWith Blueprints BlueprintsMsg (onResponse model)

            Blueprint model ->
                updateWith Blueprint BlueprintMsg (onResponse model)

            Initialize model ->
                updateWith Initialize InitializeMsg (onResponse model)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        specificSubscriptions =
            case model of
                Home _ ->
                    Sub.none

                Campaign mdl ->
                    Sub.map CampaignMsg (Campaign.subscriptions mdl)

                Execution mdl ->
                    Sub.map ExecutionMsg (Execution.subscriptions mdl)

                Draft mdl ->
                    Sub.map DraftMsg (Draft.subscriptions mdl)

                Blueprints mdl ->
                    Sub.map BlueprintsMsg (Blueprints.subscriptions mdl)

                Blueprint mdl ->
                    Sub.map BlueprintMsg (Blueprint.subscriptions mdl)

                Initialize mdl ->
                    Sub.map InitializeMsg (Initialize.subscriptions mdl)

        localStorageSubscriptions =
            Ports.LocalStorage.storageGetItemResponse LocalStorageResponse
    in
    Sub.batch
        [ specificSubscriptions
        , localStorageSubscriptions
        ]



-- SESSION


getSession : Model -> Session
getSession model =
    case model of
        Home mdl ->
            Home.getSession mdl

        Campaign mdl ->
            Campaign.getSession mdl

        Execution mdl ->
            Execution.getSession mdl

        Draft mdl ->
            Draft.getSession mdl

        Blueprints mdl ->
            Blueprints.getSession mdl

        Blueprint mdl ->
            Blueprint.getSession mdl

        Initialize mdl ->
            mdl.session


load : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
load ( mainModel, cmd ) =
    withExtraCmd cmd <|
        case mainModel of
            Home model ->
                Home.load model
                    |> updateWith Home HomeMsg

            Campaign model ->
                Campaign.load model
                    |> updateWith Campaign CampaignMsg

            Execution model ->
                Execution.load model
                    |> updateWith Execution ExecutionMsg

            Draft model ->
                Draft.load model
                    |> updateWith Draft DraftMsg

            Blueprint model ->
                Blueprint.load model
                    |> updateWith Blueprint BlueprintMsg

            Blueprints model ->
                Blueprints.load model
                    |> updateWith Blueprints BlueprintsMsg

            Initialize model ->
                Initialize.load model
                    |> updateWith Initialize InitializeMsg


withSession : Session -> Model -> Model
withSession session model =
    case model of
        Home mdl ->
            Home { mdl | session = session }

        Campaign mdl ->
            Campaign { mdl | session = session }

        Execution mdl ->
            Execution { mdl | session = session }

        Draft mdl ->
            Draft { mdl | session = session }

        Blueprints mdl ->
            Blueprints { mdl | session = session }

        Blueprint mdl ->
            Blueprint { mdl | session = session }

        Initialize mdl ->
            Initialize { mdl | session = session }
