module Main exposing (main)

--import LocalStorageUtils

import Browser exposing (Document)
import Browser.Navigation as Navigation
import Data.AuthorizationToken as AuthorizationToken exposing (AuthorizationToken)
import Data.User as User exposing (User)
import Maybe.Extra
import Page.Home as Home
import Route
import Url exposing (Url)



-- MODEL


type alias Flags =
    ()


type Model
    = Home Home.Model
    | Levels Levels.Model



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
        --        funnelState =
        --            LocalStorageUtils.initialState
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
    case model of
        Home home ->
            Home.view home



-- UPDATE


type Msg
    = ChangedUrl Url
    | ClickedLink Browser.UrlRequest


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        session =
            case model of
                Home { session } ->
                    session
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

                Just Home ->
                    ( Home { session = session }, Cmd.none )

                Just Levels ->
                    ( Levels { session = session }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



--    let
--        windowSizeSubscription =
--            Browser.Events.onResize
--                (\width height ->
--                    Resize
--                        { width = width
--                        , height = height
--                        }
--                )
--
--        localStorageProcessSubscription =
--            LocalStorageUtils.subscriptions (LocalStorageMsg << LocalStorageProcess) model
--    in
--    case model.gameState of
--        Executing _ (ExecutionRunning delay) ->
--            Sub.batch
--                [ windowSizeSubscription
--                , localStorageProcessSubscription
--                , Time.every delay (always (ExecutionMsg ExecutionStepOne))
--                ]
--
--        _ ->
--            Sub.batch
--                [ windowSizeSubscription
--                , localStorageProcessSubscription
--                ]
