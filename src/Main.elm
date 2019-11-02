module Main exposing (main)

import Api.Auth0 as Auth0
import ApplicationName exposing (applicationName)
import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.Session as Session exposing (Session)
import Extra.Cmd exposing (withExtraCmd)
import Html
import InterceptorPage.Msg
import InterceptorPage.View
import Json.Encode as Encode
import Maybe.Extra
import Page.Init
import Page.Initialize as Initialize
import Page.Load
import Page.Model exposing (PageModel)
import Page.PageMsg as PageMsg exposing (PageMsg)
import Page.Subscription
import Page.Update
import Page.View
import Ports.Console as Console
import Ports.LocalStorage
import Update.Update as Update
import Url exposing (Url)



-- MODEL


type alias Flags =
    { width : Int
    , height : Int
    , currentTimeMillis : Int
    , localStorageEntries : List ( String, Encode.Value )
    }


type alias Model =
    { session : Session
    , pageModel : PageModel
    }


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | LocalStorageResponse ( String, Encode.Value )
    | PageMsg PageMsg
    | InterceptorPageMsg InterceptorPage.Msg.Msg



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
init flags url navigationKey =
    let
        session =
            Session.init navigationKey url
    in
    { localStorageEntries = flags.localStorageEntries
    }
        |> Initialize.init
        |> load



-- VIEW


view : Model -> Document Msg
view model =
    let
        ( title, html ) =
            case InterceptorPage.View.view model.session of
                Just tuple ->
                    Tuple.mapSecond (Html.map InterceptorPageMsg) tuple

                Nothing ->
                    Page.View.view model.session model.pageModel
                        |> Tuple.mapSecond PageMsg
    in
    { title = String.concat [ title, " - ", applicationName ]
    , body = [ html ]
    }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    load <|
        case msg of
            ChangedUrl url ->
                let
                    session =
                        Session.withUrl url model.session
                in
                Page.Init.init url session
                    |> Tuple.mapBoth (setSessionAndPageModel model) (Cmd.map PageMsg)
                    |> load

            ClickedLink urlRequest ->
                case urlRequest of
                    Browser.Internal url ->
                        case url.fragment of
                            Nothing ->
                                ( model, Cmd.none )

                            Just _ ->
                                ( model
                                , Navigation.pushUrl model.session.key (Url.toString url)
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

            LocalStorageResponse ( key, _ ) ->
                ( model, Console.infoString ("3h5rn4nu8d3nksmk    " ++ key) )

            PageMsg pageMsg ->
                case pageMsg of
                    PageMsg.SessionMsg sessionMsg ->
                        Update.update sessionMsg model.session
                            |> Tuple.mapBoth (setSession model) (Cmd.map (PageMsg.SessionMsg >> PageMsg))

                    PageMsg.InternalMsg internalMsg ->
                        Page.Update.update internalMsg ( model.session, model.pageModel )
                            |> Tuple.mapBoth (setSessionAndPageModel model) (Cmd.map PageMsg)


updateWith : (a -> Model) -> (b -> Msg) -> ( a, Cmd b ) -> ( Model, Cmd Msg )
updateWith modelMap cmdMap ( model, cmd ) =
    ( modelMap model, Cmd.map cmdMap cmd )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSubscriptions =
            Page.Subscription.subscriptions model.pageModel
                |> Sub.map PageMsg

        localStorageSubscriptions =
            Ports.LocalStorage.storageGetItemResponse LocalStorageResponse
    in
    Sub.batch
        [ pageSubscriptions
        , localStorageSubscriptions
        ]



-- SESSION


setSession : Model -> Session -> Model
setSession model session =
    { model | session = session }


setSessionAndPageModel : Model -> ( Session, PageModel ) -> Model
setSessionAndPageModel model ( session, pageModel ) =
    { model | session = session, pageModel = pageModel }


load : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
load ( model, cmd ) =
    Page.Load.load model.session model.pageModel
        |> Tuple.mapBoth (setSessionAndPageModel model) (Cmd.map PageMsg)
        |> withExtraCmd cmd
