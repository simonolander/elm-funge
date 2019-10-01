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
import Page.Campaigns as Campaigns
import Page.Credits as Credits
import Page.Draft as Draft
import Page.Execution as Execution
import Page.Home as Home
import Page.Initialize as Initialize
import Page.NotFound as NotFound
import Ports.Console as Console
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
    | Campaigns Campaigns.Model
    | Credits Credits.Model
    | Execution Execution.Model
    | Draft Draft.Model
    | Blueprint Blueprint.Model
    | Blueprints Blueprints.Model
    | Initialize Initialize.Model
    | NotFound NotFound.Model


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | CampaignMsg Campaign.Msg
    | CampaignsMsg Campaigns.Msg
    | CreditsMsg Credits.Msg
    | ExecutionMsg Execution.Msg
    | DraftMsg Draft.Msg
    | HomeMsg Home.Msg
    | BlueprintsMsg Blueprints.Msg
    | BlueprintMsg Blueprint.Msg
    | InitializeMsg Initialize.Msg
    | NotFoundMsg NotFound.Msg
    | LocalStorageResponse ( String, Encode.Value )



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
                |> msgMap HomeMsg

        Campaign mdl ->
            Campaign.view mdl
                |> msgMap CampaignMsg

        Campaigns mdl ->
            Campaigns.view mdl
                |> msgMap CampaignsMsg

        Credits mdl ->
            Credits.view mdl
                |> msgMap CreditsMsg

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

        NotFound mdl ->
            NotFound.view mdl
                |> msgMap NotFoundMsg



-- UPDATE


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

            ( ExecutionMsg (Execution.SessionMsg message), _ ) ->
                getSession model
                    |> SessionUpdate.update message
                    |> updateWith (flip withSession model) (ExecutionMsg << Execution.SessionMsg)

            ( DraftMsg (Draft.InternalMsg message), Draft mdl ) ->
                Draft.update message mdl
                    |> updateWith Draft DraftMsg

            ( DraftMsg (Draft.SessionMsg message), _ ) ->
                getSession model
                    |> SessionUpdate.update message
                    |> updateWith (flip withSession model) (DraftMsg << Draft.SessionMsg)

            ( CampaignMsg (Campaign.InternalMsg message), Campaign mdl ) ->
                Campaign.update message mdl
                    |> updateWith Campaign CampaignMsg

            ( CampaignMsg (Campaign.SessionMsg message), _ ) ->
                getSession model
                    |> SessionUpdate.update message
                    |> updateWith (flip withSession model) (CampaignMsg << Campaign.SessionMsg)

            ( CampaignsMsg (Campaigns.InternalMsg message), Campaigns mdl ) ->
                Campaigns.update message mdl
                    |> updateWith Campaigns CampaignsMsg

            ( CampaignsMsg (Campaigns.SessionMsg message), _ ) ->
                getSession model
                    |> SessionUpdate.update message
                    |> updateWith (flip withSession model) (CampaignsMsg << Campaigns.SessionMsg)

            ( HomeMsg message, Home mdl ) ->
                Home.update message mdl
                    |> updateWith Home HomeMsg

            ( BlueprintsMsg (Blueprints.InternalMsg message), Blueprints mdl ) ->
                Blueprints.update message mdl
                    |> updateWith Blueprints BlueprintsMsg

            ( BlueprintsMsg (Blueprints.SessionMsg message), _ ) ->
                getSession model
                    |> SessionUpdate.update message
                    |> updateWith (flip withSession model) (BlueprintsMsg << Blueprints.SessionMsg)

            ( BlueprintMsg message, Blueprint mdl ) ->
                Blueprint.update message mdl
                    |> updateWith Blueprint BlueprintMsg

            ( InitializeMsg message, Initialize mdl ) ->
                Initialize.update message mdl
                    |> updateWith Initialize InitializeMsg

            --                Debug.todo ("Wrong message for model: " ++ Debug.toString ( message, mdl ))
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
                NotFound.init session
                    |> updateWith NotFound NotFoundMsg

            Just Route.Home ->
                Home.init session
                    |> updateWith Home HomeMsg

            Just (Route.Campaign campaignId maybeLevelId) ->
                Campaign.init campaignId maybeLevelId session
                    |> updateWith Campaign CampaignMsg

            Just Route.Campaigns ->
                Campaigns.init session
                    |> updateWith Campaigns CampaignsMsg

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

            Just Route.Credits ->
                Credits.init session
                    |> updateWith Credits CreditsMsg

            Just Route.NotFound ->
                NotFound.init session
                    |> updateWith NotFound NotFoundMsg


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
                                    "1d2c9ff5    " ++ name ++ " " ++ request ++ " not found"
                            in
                            ( { mdl | session = notFound request mdl.session }
                            , Cmd.batch [ cmd, Console.errorString errorMessage ]
                            )

                        Err error ->
                            ( { mdl | session = failure request error mdl.session }
                            , Cmd.batch [ cmd, Console.errorString (Decode.errorToString error) ]
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
                            , Cmd.batch [ cmd, Console.errorString (Decode.errorToString error) ]
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

            Campaigns model ->
                updateWith Campaigns CampaignsMsg (onResponse model)

            Credits model ->
                updateWith Credits CreditsMsg (onResponse model)

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

            NotFound model ->
                updateWith NotFound NotFoundMsg (onResponse model)



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

                Campaigns mdl ->
                    Sub.map CampaignsMsg (Campaigns.subscriptions mdl)

                Credits mdl ->
                    Sub.map CreditsMsg (Credits.subscriptions mdl)

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

                NotFound mdl ->
                    Sub.map NotFoundMsg (NotFound.subscriptions mdl)

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
            mdl.session

        Campaign mdl ->
            mdl.session

        Campaigns mdl ->
            mdl.session

        Credits mdl ->
            mdl.session

        Execution mdl ->
            mdl.session

        Draft mdl ->
            Draft.getSession mdl

        Blueprints mdl ->
            mdl.session

        Blueprint mdl ->
            Blueprint.getSession mdl

        Initialize mdl ->
            mdl.session

        NotFound mdl ->
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

            Campaigns model ->
                Campaigns.load model
                    |> updateWith Campaigns CampaignsMsg

            Credits model ->
                Credits.load model
                    |> updateWith Credits CreditsMsg

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

            NotFound model ->
                NotFound.load model
                    |> updateWith NotFound NotFoundMsg


withSession : Session -> Model -> Model
withSession session model =
    case model of
        Home mdl ->
            Home { mdl | session = session }

        Campaign mdl ->
            Campaign { mdl | session = session }

        Campaigns mdl ->
            Campaigns { mdl | session = session }

        Credits mdl ->
            Credits { mdl | session = session }

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

        NotFound mdl ->
            NotFound { mdl | session = session }
