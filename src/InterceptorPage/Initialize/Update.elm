module InterceptorPage.Initialize.Update exposing (update)

import Data.Session exposing (Session)
import InterceptorPage.Initialize.Msg exposing (Msg)
import Update.SessionMsg exposing (SessionMsg)


update : Msg -> Session -> ( Session, Cmd SessionMsg )
update msg session =
    ( session, Cmd.none )


init :
    { navigationKey : Browser.Navigation.Key
    , localStorageEntries : List ( String, Encode.Value )
    , url : Url.Url
    }
    -> ( Model, Cmd Msg )
init { localStorageEntries } =
    let
        ( route, accessToken, accessTokenCmd ) =
            case Auth0.loginResponseFromUrl url of
                Just loginResponse ->
                    ( loginResponse.route
                    , Just loginResponse.accessToken
                    , Cmd.none
                    )

                Nothing ->
                    let
                        accessTokenResult =
                            localStorageEntries
                                |> List.filterMap AccessToken.localStorageResponse
                                |> List.head
                                |> Maybe.map .result
                    in
                    ( Route.fromUrl url
                        |> Maybe.withDefault Route.Home
                    , accessTokenResult
                        |> Maybe.andThen Result.toMaybe
                        |> Maybe.Extra.join
                    , case accessTokenResult of
                        Just (Err error) ->
                            Console.errorString (Decode.errorToString error)

                        _ ->
                            Cmd.none
                    )

        accessTokenState =
            accessToken
                |> Maybe.map Verifying
                |> Maybe.withDefault Missing

        ( maybeUserInfo, userInfoErrors ) =
            localStorageEntries
                |> List.filterMap UserInfo.localStorageResponse
                |> RequestResult.split
                |> Tuple.mapFirst (List.filterMap Tuple.second >> List.head)

        ( localDrafts, localDraftErrors ) =
            localStorageEntries
                |> List.filterMap Draft.localStorageResponse
                |> RequestResult.split

        ( expectedDrafts, expectedDraftErrors ) =
            localStorageEntries
                |> List.filterMap Draft.localRemoteStorageResponse
                |> RequestResult.split

        ( localDraftBooks, localDraftBookErrors ) =
            localStorageEntries
                |> List.filterMap DraftBook.localStorageResponse
                |> RequestResult.split

        ( localSolutions, localSolutionErrors ) =
            localStorageEntries
                |> List.filterMap Solution.localStorageResponse
                |> RequestResult.split

        ( expectedSolutions, expectedSolutionErrors ) =
            localStorageEntries
                |> List.filterMap Solution.localRemoteStorageResponse
                |> RequestResult.split

        ( localSolutionBooks, localSolutionBookErrors ) =
            localStorageEntries
                |> List.filterMap SolutionBook.localStorageResponse
                |> RequestResult.split

        ( localBlueprints, localBlueprintErrors ) =
            localStorageEntries
                |> List.filterMap Blueprint.localStorageResponse
                |> RequestResult.split

        ( expectedBlueprints, expectedBlueprintErrors ) =
            localStorageEntries
                |> List.filterMap Blueprint.localRemoteStorageResponse
                |> RequestResult.split

        model : Model
        model =
            { --                    |> Levels.withTestLevels
              route = route
            , accessTokenState = accessTokenState
            , expectedUserInfo = maybeUserInfo
            , actualUserInfo = RemoteData.NotAsked
            , localDraftBooks = Dict.fromList localDraftBooks
            , localDrafts = Dict.fromList localDrafts
            , expectedDrafts = Dict.fromList expectedDrafts
            , actualDrafts = Cache.empty
            , savingDrafts = Dict.empty
            , localSolutionBooks = Dict.fromList localSolutionBooks
            , localSolutions = Dict.fromList localSolutions
            , expectedSolutions = Dict.fromList expectedSolutions
            , actualSolutions = Cache.empty
            , savingSolutions = Dict.empty
            , localBlueprints = Dict.fromList localBlueprints
            , expectedBlueprints = Dict.fromList expectedBlueprints
            , actualBlueprints = Cache.empty
            , savingBlueprints = Dict.empty
            }

        cmd : Cmd Msg
        cmd =
            Cmd.batch
                [ accessTokenCmd
                , Cmd.batch
                    (List.map
                        (List.map Tuple.second
                            >> List.map Decode.errorToString
                            >> List.map Console.errorString
                            >> Cmd.batch
                        )
                        [ userInfoErrors
                        , localDraftErrors
                        , expectedDraftErrors
                        , localDraftBookErrors
                        , localSolutionErrors
                        , expectedSolutionErrors
                        , localSolutionBookErrors
                        , localBlueprintErrors
                        , expectedBlueprintErrors
                        ]
                    )
                ]
    in
    ( model, cmd )
