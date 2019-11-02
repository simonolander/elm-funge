module Page.Initialize exposing
    ( Model
    , Msg
    , init
    , load
    , subscriptions
    , update
    , view
    )

import Api.Auth0 as Auth0
import ApplicationName exposing (applicationName)
import Basics.Extra exposing (flip)
import Browser exposing (Document)
import Browser.Navigation
import Data.AccessToken as AccessToken exposing (AccessToken)
import Data.Blueprint as Blueprint exposing (Blueprint)
import Data.BlueprintId exposing (BlueprintId)
import Data.Cache as Cache exposing (Cache)
import Data.Draft as Draft exposing (Draft)
import Data.DraftBook as DraftBook exposing (DraftBook)
import Data.DraftId exposing (DraftId)
import Data.GetError as GetError exposing (GetError)
import Data.LevelId exposing (LevelId)
import Data.OneOrBoth as OneOrBoth exposing (OneOrBoth(..))
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.SaveError as SaveError exposing (SaveError)
import Data.Session as Session exposing (Session)
import Data.Solution as Solution exposing (Solution)
import Data.SolutionBook as SolutionBook exposing (SolutionBook)
import Data.SolutionId exposing (SolutionId)
import Data.SubmitSolutionError as SubmitSolutionError exposing (SubmitSolutionError)
import Data.User as User
import Data.UserInfo as UserInfo exposing (UserInfo)
import Dict exposing (Dict)
import Element exposing (..)
import Element.Font as Font
import Extra.Cmd exposing (noCmd, withCmd)
import Extra.List exposing (flist)
import Json.Decode as Decode
import Json.Encode as Encode
import List.Extra
import Maybe.Extra
import Ports.Console as Console
import Random
import RemoteData
import Route exposing (Route)
import String.Extra
import Url
import View.Constant exposing (color)
import View.ErrorScreen
import View.Info as Info
import View.Layout
import View.LoadingScreen
import ViewComponents



-- MODEL


type ConflictResolution id a
    = DoNothing
    | OverwriteLocal a
    | OverwriteActual a
    | DiscardLocal id
    | DiscardActual id
    | ResolveManually
        { localOrExpected : OneOrBoth a
        , maybeActual : Maybe a
        }
    | Error GetError


type Saving e
    = Saving
    | Saved (Maybe e)


type AccessTokenState
    = Missing
    | Expired AccessToken
    | Verifying AccessToken
    | Verified
        { accessToken : AccessToken
        , userInfo : UserInfo
        }


type alias Model =
    { route : Route
    , accessTokenState : AccessTokenState
    , expectedUserInfo : Maybe UserInfo
    , actualUserInfo : RemoteData.RemoteData GetError UserInfo
    , localDraftBooks : Dict LevelId DraftBook
    , localDrafts : Dict DraftId (Maybe Draft)
    , expectedDrafts : Dict DraftId (Maybe Draft)
    , actualDrafts : Cache DraftId GetError (Maybe Draft)
    , savingDrafts : Dict DraftId (Saving SaveError)
    , localSolutionBooks : Dict LevelId SolutionBook
    , localSolutions : Dict SolutionId (Maybe Solution)
    , expectedSolutions : Dict SolutionId (Maybe Solution)
    , actualSolutions : Cache SolutionId GetError (Maybe Solution)
    , savingSolutions : Dict SolutionId (Saving SubmitSolutionError)
    , localBlueprints : Dict BlueprintId (Maybe Blueprint)
    , expectedBlueprints : Dict BlueprintId (Maybe Blueprint)
    , actualBlueprints : Cache BlueprintId GetError (Maybe Blueprint)
    , savingBlueprints : Dict BlueprintId (Saving SaveError)
    }


type Msg
    = GeneratedSolution Solution
    | GotUserInfoResponse (Result GetError UserInfo)
    | GotDraftLoadResponse DraftId (Result GetError (Maybe Draft))
    | GotDraftDeleteResponse DraftId (Maybe SaveError)
    | GotLoadBlueprintResponse BlueprintId (Result GetError (Maybe Blueprint))
    | GotBlueprintSaveResponse Blueprint (Maybe SaveError)
    | GotBlueprintDeleteResponse BlueprintId (Maybe SaveError)
    | GotDraftSaveResponse Draft (Maybe SaveError)
    | GotSolutionSaveResponse Solution (Maybe SubmitSolutionError)
    | ClickedContinueOffline
    | ClickedDraftDiscardLocal DraftId
    | ClickedDraftDiscardActual DraftId
    | ClickedDraftOverwriteActual Draft
    | ClickedDraftOverwriteLocal Draft
    | ClickedBlueprintOverwriteActual Blueprint
    | ClickedBlueprintOverwriteLocal Blueprint
    | ClickedBlueprintDiscardLocal BlueprintId
    | ClickedBlueprintDiscardActual BlueprintId
    | ClickedImportLocalData
    | ClickedDeleteLocalData
    | ClickedSignInToOtherAccount


load : Model -> ( Model, Cmd Msg )
load =
    let
        loadUserData model =
            case ( model.accessTokenState, model.actualUserInfo ) of
                ( Verifying accessToken, RemoteData.NotAsked ) ->
                    ( { model
                        | actualUserInfo = RemoteData.Loading
                      }
                    , Cmd.batch
                        [ UserInfo.loadFromServer accessToken GotUserInfoResponse
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        loadDrafts model =
            case model.accessTokenState of
                Verified { accessToken } ->
                    let
                        loadingDraftIds =
                            OneOrBoth.fromDicts model.localDrafts model.expectedDrafts
                                |> List.filterMap OneOrBoth.join
                                |> List.filter (OneOrBoth.areSame Draft.eq >> not)
                                |> List.map (OneOrBoth.map .id >> OneOrBoth.any)
                                |> List.filter (flip Cache.get model.actualDrafts >> RemoteData.isNotAsked)
                    in
                    ( loadingDraftIds
                        |> List.foldl Cache.loading model.actualDrafts
                        |> flip withActualDrafts model
                    , Cmd.batch
                        [ loadingDraftIds
                            |> List.map (\draftId -> Draft.loadFromServer (GotDraftLoadResponse draftId) accessToken draftId)
                            |> Cmd.batch
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        publishSolutions : Model -> ( Model, Cmd Msg )
        publishSolutions model =
            case model.accessTokenState of
                Verified { accessToken } ->
                    let
                        unpublishedSolutions =
                            Dict.values model.localSolutions
                                |> Maybe.Extra.values
                                |> List.filter (.id >> flip Dict.member model.expectedSolutions >> not)
                                |> List.filter (.id >> flip Dict.member model.savingSolutions >> not)

                        savingSolutions =
                            List.foldl (\solution -> Dict.insert solution.id Saving) model.savingSolutions unpublishedSolutions
                    in
                    ( { model | savingSolutions = savingSolutions }
                    , unpublishedSolutions
                        |> List.map (\solution -> Solution.saveToServer (GotSolutionSaveResponse solution) accessToken solution)
                        |> Cmd.batch
                    )

                _ ->
                    ( model, Cmd.none )

        loadBlueprints model =
            case model.accessTokenState of
                Verified { accessToken } ->
                    let
                        blueprintIds =
                            List.concat
                                [ Dict.keys model.localBlueprints
                                , Dict.keys model.expectedBlueprints
                                ]
                                |> List.Extra.unique
                                |> List.filter
                                    (\id ->
                                        let
                                            localBlueprint =
                                                Dict.get id model.localBlueprints

                                            expectedBlueprint =
                                                Dict.get id model.localBlueprints

                                            isNotAsked =
                                                Cache.isNotAsked id model.actualBlueprints
                                        in
                                        isNotAsked && localBlueprint /= expectedBlueprint
                                    )

                        actualBlueprints =
                            List.foldl Cache.loading model.actualBlueprints blueprintIds
                    in
                    ( { model | actualBlueprints = actualBlueprints }
                    , List.map (Blueprint.loadFromServerByBlueprintId GotLoadBlueprintResponse accessToken) blueprintIds
                        |> Cmd.batch
                    )

                _ ->
                    ( model, Cmd.none )

        finish model =
            case model.accessTokenState of
                Missing ->
                    let
                        user =
                            model.session.user
                                |> User.withUserInfo model.expectedUserInfo

                        session =
                            model.session
                                |> Session.withUser user
                    in
                    ( { model | session = session }
                    , Route.replaceUrl model.session.key model.route
                    )

                Expired _ ->
                    ( model, Cmd.none )

                Verifying _ ->
                    ( model, Cmd.none )

                Verified { accessToken, userInfo } ->
                    let
                        hasDraftConflicts =
                            OneOrBoth.fromDicts model.localDrafts model.expectedDrafts
                                |> List.filterMap OneOrBoth.join
                                |> List.all (OneOrBoth.areSame Draft.eq)
                                |> not

                        hasSavingDrafts =
                            model.savingDrafts
                                |> Dict.values
                                |> List.filter isSaving
                                |> List.isEmpty
                                |> not

                        hasBlueprintConflicts =
                            OneOrBoth.fromDicts model.localBlueprints model.expectedBlueprints
                                |> List.all (OneOrBoth.areSame (==))
                                |> not

                        hasSavingBlueprints =
                            model.savingBlueprints
                                |> Dict.values
                                |> List.filter isSaving
                                |> List.isEmpty
                                |> not

                        hasSavingSolutions =
                            model.savingSolutions
                                |> Dict.values
                                |> List.filter isSaving
                                |> List.isEmpty
                                |> not

                        done =
                            List.any identity
                                [ hasDraftConflicts
                                , hasSavingDrafts
                                , hasBlueprintConflicts
                                , hasSavingBlueprints
                                , hasSavingSolutions
                                ]
                                |> not
                    in
                    if done then
                        let
                            user =
                                User.authorizedUser accessToken userInfo

                            draftCache =
                                { local = model.localDrafts
                                , expected = model.expectedDrafts
                                , actual = model.actualDrafts
                                }

                            blueprintCache =
                                { local = model.localBlueprints
                                , expected = model.expectedBlueprints
                                , actual = model.actualBlueprints
                                }

                            session =
                                model.session
                                    |> Session.withUser user
                                    |> Session.withDraftCache draftCache
                                    |> Session.withBlueprintCache blueprintCache

                            saveOrDelete save delete ( id, maybeValue ) =
                                Maybe.withDefault (delete id) (Maybe.map save maybeValue)

                            saveDraftsLocallyCmd =
                                Cmd.batch
                                    [ Dict.toList model.localDrafts
                                        |> List.map (saveOrDelete Draft.saveToLocalStorage Draft.removeFromLocalStorage)
                                        |> Cmd.batch
                                    , Dict.toList model.expectedDrafts
                                        |> List.map (saveOrDelete Draft.saveRemoteToLocalStorage Draft.removeRemoteFromLocalStorage)
                                        |> Cmd.batch
                                    ]

                            saveBlueprintsLocallyCmd =
                                Cmd.batch
                                    [ Dict.values model.localBlueprints
                                        |> List.map Blueprint.saveToLocalStorage
                                        |> Cmd.batch
                                    , Dict.values model.expectedBlueprints
                                        |> List.map Blueprint.saveRemoteToLocalStorage
                                        |> Cmd.batch
                                    , Cache.toList model.actualBlueprints
                                        |> List.filterMap (\( key, data ) -> Maybe.map (Tuple.pair key) (RemoteData.toMaybe data))
                                        |> List.filter (Tuple.second >> Maybe.Extra.isNothing)
                                        |> List.map (Tuple.first >> flist [ Blueprint.removeFromLocalStorage, Blueprint.removeRemoteFromLocalStorage ] >> Cmd.batch)
                                        |> Cmd.batch
                                    ]
                        in
                        ( { model | session = session }
                        , Cmd.batch
                            [ AccessToken.saveToLocalStorage accessToken
                            , UserInfo.saveToLocalStorage userInfo
                            , saveDraftsLocallyCmd
                            , saveBlueprintsLocallyCmd
                            , Route.replaceUrl model.session.key model.route
                            ]
                        )

                    else
                        ( model, Cmd.none )
    in
    Extra.Cmd.fold
        [ loadUserData
        , loadDrafts
        , loadBlueprints
        , publishSolutions
        , finish
        ]


withSavingDraft : Draft -> Model -> Model
withSavingDraft draft model =
    { model | savingDrafts = Dict.insert draft.id Saving model.savingDrafts }


withActualDrafts : Cache DraftId GetError (Maybe Draft) -> Model -> Model
withActualDrafts actualDrafts model =
    { model | actualDrafts = actualDrafts }


withExpiredAccessToken : Model -> Model
withExpiredAccessToken model =
    { model
        | accessTokenState =
            case model.accessTokenState of
                Missing ->
                    Missing

                Expired accessToken ->
                    Expired accessToken

                Verifying accessToken ->
                    Expired accessToken

                Verified { accessToken } ->
                    Expired accessToken
    }


isSaving : Saving e -> Bool
isSaving saving =
    case saving of
        Saving ->
            True

        Saved _ ->
            False



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GeneratedSolution solution ->
            let
                localSolutions =
                    Dict.insert solution.id (Just solution) model.localSolutions

                localSolutionBooks =
                    Dict.update
                        solution.levelId
                        (Maybe.withDefault (SolutionBook.empty solution.levelId) >> SolutionBook.withSolutionId solution.id >> Just)
                        model.localSolutionBooks
            in
            ( { model
                | localSolutions = localSolutions
                , localSolutionBooks = localSolutionBooks
              }
            , Cmd.none
            )

        GotUserInfoResponse result ->
            let
                modelWithActualUserInfo =
                    { model | actualUserInfo = RemoteData.fromResult result }
            in
            case result of
                Ok actualUserInfo ->
                    let
                        verified =
                            case modelWithActualUserInfo.accessTokenState of
                                Verifying accessToken ->
                                    Verified
                                        { accessToken = accessToken
                                        , userInfo = actualUserInfo
                                        }

                                _ ->
                                    modelWithActualUserInfo.accessTokenState
                    in
                    case modelWithActualUserInfo.expectedUserInfo of
                        Just expectedUserInfo ->
                            if expectedUserInfo.sub == actualUserInfo.sub then
                                ( { modelWithActualUserInfo
                                    | expectedUserInfo = Just actualUserInfo
                                    , accessTokenState = verified
                                  }
                                , Cmd.none
                                )

                            else
                                ( modelWithActualUserInfo
                                , Cmd.none
                                )

                        Nothing ->
                            let
                                localStorageIsClean =
                                    modelWithActualUserInfo.localDrafts
                                        |> Dict.isEmpty

                                -- TODO Check blueprints
                            in
                            if localStorageIsClean then
                                ( { modelWithActualUserInfo
                                    | expectedUserInfo = Just actualUserInfo
                                    , accessTokenState = verified
                                  }
                                , Cmd.none
                                )

                            else
                                ( modelWithActualUserInfo
                                , Cmd.none
                                )

                Err error ->
                    ( withExpiredAccessToken modelWithActualUserInfo
                    , GetError.consoleError error
                    )

        GotDraftLoadResponse draftId result ->
            let
                modelWithActualDraft =
                    Cache.withResult draftId result model.actualDrafts
                        |> flip withActualDrafts model

                resolution =
                    determineConflictResolution
                        { id = draftId
                        , maybeLocal = Dict.get draftId modelWithActualDraft.localDrafts
                        , maybeExpected = Dict.get draftId modelWithActualDraft.expectedDrafts
                        , remoteActual = RemoteData.fromResult result
                        , eq = Draft.eq
                        }

                overwriteLocalDraft d m =
                    ( { m | localDrafts = Dict.insert d.id d m.localDrafts }, Cmd.none )

                overwriteExpectedDraft d m =
                    ( { m | expectedDrafts = Dict.insert d.id d m.expectedDrafts }, Cmd.none )

                overwriteActualDraft d m =
                    case m.accessTokenState of
                        Verified { accessToken } ->
                            ( withSavingDraft d m, Draft.saveToServer (GotDraftSaveResponse d) accessToken d )

                        _ ->
                            ( m, Console.errorString "aa167786    Access token expired during initialization" )

                discardLocalDraft id m =
                    ( { m | localDrafts = Dict.remove id m.localDrafts }, Cmd.none )

                discardExpectedDraft id m =
                    ( { m | expectedDrafts = Dict.remove id m.expectedDrafts }, Cmd.none )

                discardActualDraft id m =
                    ( { m | actualDrafts = Cache.remove id m.actualDrafts }, Cmd.none )
            in
            resolveConflict
                { overwriteLocal = overwriteLocalDraft
                , overwriteExpected = overwriteExpectedDraft
                , overwriteActual = overwriteActualDraft
                , discardLocal = discardLocalDraft
                , discardExpected = discardExpectedDraft
                , discardActual = discardActualDraft
                }
                modelWithActualDraft
                resolution

        GotDraftSaveResponse draft maybeError ->
            let
                modelWithSavedDraft =
                    { model | savingDrafts = Dict.insert draft.id (Saved maybeError) model.savingDrafts }
            in
            case maybeError of
                Nothing ->
                    ( { modelWithSavedDraft
                        | actualDrafts = Cache.withValue draft.id (Just draft) modelWithSavedDraft.actualDrafts
                        , localDrafts = Dict.insert draft.id draft modelWithSavedDraft.localDrafts
                        , expectedDrafts = Dict.insert draft.id draft modelWithSavedDraft.expectedDrafts
                      }
                    , Cmd.none
                    )

                Just error ->
                    case error of
                        SaveError.InvalidAccessToken _ ->
                            ( withExpiredAccessToken modelWithSavedDraft
                            , SaveError.consoleError error
                            )

                        _ ->
                            ( modelWithSavedDraft
                            , SaveError.consoleError error
                            )

        GotDraftDeleteResponse draftId maybeError ->
            let
                modelWithSavedDraft =
                    { model | savingDrafts = Dict.insert draftId (Saved maybeError) model.savingDrafts }
            in
            case maybeError of
                Nothing ->
                    ( { modelWithSavedDraft
                        | actualDrafts = Cache.withValue draftId Nothing modelWithSavedDraft.actualDrafts
                        , localDrafts = Dict.remove draftId modelWithSavedDraft.localDrafts
                        , expectedDrafts = Dict.remove draftId modelWithSavedDraft.expectedDrafts
                      }
                    , Cmd.none
                    )

                Just error ->
                    case error of
                        SaveError.InvalidAccessToken _ ->
                            ( withExpiredAccessToken modelWithSavedDraft
                            , SaveError.consoleError error
                            )

                        _ ->
                            ( modelWithSavedDraft
                            , SaveError.consoleError error
                            )

        GotBlueprintSaveResponse blueprint maybeError ->
            let
                modelWithSaveResponse =
                    { model | savingBlueprints = Dict.insert blueprint.id (Saved maybeError) model.savingBlueprints }
            in
            case maybeError of
                Just error ->
                    case error of
                        SaveError.InvalidAccessToken _ ->
                            ( withExpiredAccessToken modelWithSaveResponse
                            , SaveError.consoleError error
                            )

                        _ ->
                            ( modelWithSaveResponse
                            , SaveError.consoleError error
                            )

                Nothing ->
                    ( { modelWithSaveResponse
                        | actualBlueprints = Cache.withValue blueprint.id (Just blueprint) modelWithSaveResponse.actualBlueprints
                        , localBlueprints = Dict.insert blueprint.id blueprint modelWithSaveResponse.localBlueprints
                        , expectedBlueprints = Dict.insert blueprint.id blueprint modelWithSaveResponse.expectedBlueprints
                      }
                    , Cmd.none
                    )

        GotBlueprintDeleteResponse blueprintId maybeError ->
            let
                modelWithSavedBlueprint =
                    { model | savingBlueprints = Dict.insert blueprintId (Saved maybeError) model.savingBlueprints }
            in
            case maybeError of
                Nothing ->
                    ( { modelWithSavedBlueprint
                        | actualBlueprints = Cache.withValue blueprintId Nothing modelWithSavedBlueprint.actualBlueprints
                        , localBlueprints = Dict.remove blueprintId modelWithSavedBlueprint.localBlueprints
                        , expectedBlueprints = Dict.remove blueprintId modelWithSavedBlueprint.expectedBlueprints
                      }
                    , Cmd.none
                    )

                Just error ->
                    case error of
                        SaveError.InvalidAccessToken _ ->
                            ( withExpiredAccessToken modelWithSavedBlueprint
                            , SaveError.consoleError error
                            )

                        _ ->
                            ( modelWithSavedBlueprint
                            , SaveError.consoleError error
                            )

        GotSolutionSaveResponse solution maybeError ->
            let
                modelWithSavedResponse =
                    { model
                        | savingSolutions = Dict.insert solution.id (Saved maybeError) model.savingSolutions
                    }
            in
            case maybeError of
                Nothing ->
                    modelWithSavedResponse
                        |> withCmd (Solution.saveRemoteToLocalStorage solution)

                Just error ->
                    case error of
                        SubmitSolutionError.NetworkError ->
                            --TODO Offline
                            withExpiredAccessToken model
                                |> noCmd

                        SubmitSolutionError.InvalidAccessToken message ->
                            withExpiredAccessToken model
                                |> noCmd

                        SubmitSolutionError.Duplicate ->
                            let
                                localSolutionBooks =
                                    Dict.update solution.levelId (Maybe.map (SolutionBook.withoutSolutionId solution.id)) model.localSolutionBooks

                                localSolutions =
                                    Dict.remove solution.id model.localSolutions

                                expectedSolutions =
                                    Dict.remove solution.id model.expectedSolutions

                                actualSolutions =
                                    Cache.withValue solution.id Nothing model.actualSolutions
                            in
                            ( { model
                                | localSolutionBooks = localSolutionBooks
                                , localSolutions = localSolutions
                                , expectedSolutions = expectedSolutions
                                , actualSolutions = actualSolutions
                              }
                            , Cmd.batch
                                [ Solution.removeFromLocalStorage solution.id
                                , Solution.removeRemoteFromLocalStorage solution.id
                                , SolutionBook.removeSolutionIdFromLocalStorage solution.id solution.levelId
                                ]
                            )

                        SubmitSolutionError.ConflictingId ->
                            let
                                localSolutionBooks =
                                    Dict.update solution.levelId (Maybe.map (SolutionBook.withoutSolutionId solution.id)) model.localSolutionBooks

                                localSolutions =
                                    Dict.remove solution.id model.localSolutions

                                expectedSolutions =
                                    Dict.remove solution.id model.expectedSolutions

                                actualSolutions =
                                    Cache.withValue solution.id Nothing model.actualSolutions
                            in
                            ( { model
                                | localSolutionBooks = localSolutionBooks
                                , localSolutions = localSolutions
                                , expectedSolutions = expectedSolutions
                                , actualSolutions = actualSolutions
                              }
                            , Cmd.batch
                                [ Solution.removeFromLocalStorage solution.id
                                , Solution.removeRemoteFromLocalStorage solution.id
                                , SolutionBook.removeSolutionIdFromLocalStorage solution.id solution.levelId
                                , Random.generate GeneratedSolution (Solution.generator solution.levelId solution.score solution.board)
                                ]
                            )

                        SubmitSolutionError.Other _ ->
                            modelWithSavedResponse
                                |> withCmd (SubmitSolutionError.consoleError error)

        ClickedContinueOffline ->
            ( { model
                | accessTokenState = Missing
              }
            , Cmd.none
            )

        ClickedDraftOverwriteActual draft ->
            case model.accessTokenState of
                Verified { accessToken } ->
                    model
                        |> withSavingDraft draft
                        |> withCmd (Draft.saveToServer (GotDraftSaveResponse draft) accessToken draft)

                _ ->
                    ( model, Console.errorString "3l4aq6eg50kkfxj2    Access token expired during initialization" )

        ClickedDraftOverwriteLocal draft ->
            ( { model
                | localDrafts = Dict.insert draft.id draft model.localDrafts
                , expectedDrafts = Dict.insert draft.id draft model.expectedDrafts
              }
            , Cmd.none
            )

        ClickedDraftDiscardLocal draftId ->
            ( { model
                | localDrafts = Dict.remove draftId model.localDrafts
                , expectedDrafts = Dict.remove draftId model.expectedDrafts
              }
            , Cmd.none
            )

        ClickedDraftDiscardActual draftId ->
            case model.accessTokenState of
                Verified { accessToken } ->
                    ( { model | savingDrafts = Dict.insert draftId Saving model.savingDrafts }
                    , Draft.deleteFromServer GotDraftDeleteResponse accessToken draftId
                    )

                _ ->
                    ( model, Console.errorString "zxhy329qlqfv7czn    Can't discard draft, access token expired during initialization" )

        ClickedBlueprintOverwriteActual blueprint ->
            case model.accessTokenState of
                Verified { accessToken } ->
                    ( { model | savingBlueprints = Dict.insert blueprint.id Saving model.savingBlueprints }
                    , Blueprint.saveToServer GotBlueprintSaveResponse accessToken blueprint
                    )

                _ ->
                    ( model, Console.errorString "5mn2a7llho75d04s    Can't discard blueprint, access token expired during initialization" )

        ClickedBlueprintOverwriteLocal blueprint ->
            ( { model
                | localBlueprints = Dict.insert blueprint.id blueprint model.localBlueprints
                , expectedBlueprints = Dict.insert blueprint.id blueprint model.expectedBlueprints
              }
            , Cmd.none
            )

        ClickedBlueprintDiscardLocal blueprintId ->
            ( { model
                | localBlueprints = Dict.remove blueprintId model.localBlueprints
                , expectedBlueprints = Dict.remove blueprintId model.expectedBlueprints
              }
            , Cmd.none
            )

        ClickedBlueprintDiscardActual blueprintId ->
            case model.accessTokenState of
                Verified { accessToken } ->
                    ( { model | savingBlueprints = Dict.insert blueprintId Saving model.savingBlueprints }
                    , Blueprint.deleteFromServer GotBlueprintDeleteResponse accessToken blueprintId
                    )

                _ ->
                    ( model, Console.errorString "5mn2a7llho75d04s    Can't discard blueprint, access token expired during initialization" )

        ClickedImportLocalData ->
            case ( model.accessTokenState, RemoteData.toMaybe model.actualUserInfo ) of
                ( Verifying accessToken, Just actualUserInfo ) ->
                    ( { model
                        | accessTokenState = Verified { accessToken = accessToken, userInfo = actualUserInfo }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        ClickedDeleteLocalData ->
            case ( model.accessTokenState, RemoteData.toMaybe model.actualUserInfo ) of
                ( Verifying accessToken, Just actualUserInfo ) ->
                    ( { model
                        | accessTokenState =
                            Verified
                                { accessToken = accessToken
                                , userInfo = actualUserInfo
                                }
                        , localDrafts = Dict.empty
                        , expectedDrafts = Dict.empty
                        , localBlueprints = Dict.empty
                        , expectedBlueprints = Dict.empty
                      }
                    , Cmd.batch
                        [ Cmd.batch
                            [ Dict.keys model.localDrafts
                                |> List.map Draft.removeFromLocalStorage
                                |> Cmd.batch
                            , Dict.keys model.expectedDrafts
                                |> List.map Draft.removeRemoteFromLocalStorage
                                |> Cmd.batch
                            , Dict.keys model.localDraftBooks
                                |> List.map DraftBook.removeFromLocalStorage
                                |> Cmd.batch
                            ]
                        , Cmd.batch
                            [ Dict.keys model.localBlueprints
                                |> List.map Blueprint.removeFromLocalStorage
                                |> Cmd.batch
                            , Dict.keys model.expectedBlueprints
                                |> List.map Blueprint.removeRemoteFromLocalStorage
                                |> Cmd.batch
                            , BlueprintBook.removeFromLocalStorage
                            ]
                        ]
                    )

                _ ->
                    ( model, Cmd.none )

        ClickedSignInToOtherAccount ->
            ( model
            , Browser.Navigation.load (Auth0.reLogin (Route.toUrl model.route))
            )

        GotLoadBlueprintResponse blueprintId result ->
            let
                modelWithActualBlueprint =
                    { model | actualBlueprints = Cache.withResult blueprintId result model.actualBlueprints }

                resolution =
                    determineConflictResolution
                        { id = blueprintId
                        , maybeLocal = Dict.get blueprintId modelWithActualBlueprint.localBlueprints
                        , maybeExpected = Dict.get blueprintId modelWithActualBlueprint.expectedBlueprints
                        , remoteActual = RemoteData.fromResult result
                        , eq = (==)
                        }

                overwriteLocalBlueprint d m =
                    ( { m | localBlueprints = Dict.insert d.id d m.localBlueprints }, Cmd.none )

                overwriteExpectedBlueprint d m =
                    ( { m | expectedBlueprints = Dict.insert d.id d m.expectedBlueprints }, Cmd.none )

                overwriteActualBlueprint d m =
                    case m.accessTokenState of
                        Verified { accessToken } ->
                            ( { m | savingBlueprints = Dict.insert d.id Saving m.savingBlueprints }
                            , Blueprint.saveToServer GotBlueprintSaveResponse accessToken d
                            )

                        _ ->
                            ( m, Console.errorString "0liotkiw    Access token expired during initialization" )

                discardLocalBlueprint id m =
                    ( { m | localBlueprints = Dict.remove id m.localBlueprints }, Cmd.none )

                discardExpectedBlueprint id m =
                    ( { m | expectedBlueprints = Dict.remove id m.expectedBlueprints }, Cmd.none )

                discardActualBlueprint id m =
                    ( { m | actualBlueprints = Cache.remove id m.actualBlueprints }, Cmd.none )
            in
            resolveConflict
                { overwriteLocal = overwriteLocalBlueprint
                , overwriteExpected = overwriteExpectedBlueprint
                , overwriteActual = overwriteActualBlueprint
                , discardLocal = discardLocalBlueprint
                , discardExpected = discardExpectedBlueprint
                , discardActual = discardActualBlueprint
                }
                modelWithActualBlueprint
                resolution



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions =
    always Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        element =
            case model.accessTokenState of
                Missing ->
                    View.ErrorScreen.layout "Missing access token"

                Expired _ ->
                    viewExpiredAccessToken model ""
                        |> View.Layout.layout

                Verifying _ ->
                    case model.actualUserInfo of
                        RemoteData.NotAsked ->
                            View.ErrorScreen.layout "Todo: User info not asked"

                        RemoteData.Loading ->
                            View.LoadingScreen.layout "Verifying credentials"

                        RemoteData.Failure error ->
                            viewHttpError model error
                                |> View.Layout.layout

                        RemoteData.Success actualUserInfo ->
                            View.Layout.layout <|
                                Info.view
                                    { title = "New sign in detected"
                                    , icon =
                                        { src = "assets/exception-orange.svg"
                                        , description = "Alert icon"
                                        }
                                    , elements =
                                        case model.expectedUserInfo of
                                            Just expectedUserInfo ->
                                                [ paragraph [ Font.center ]
                                                    [ text "You're trying to sign in as "
                                                    , text actualUserInfo.sub |> el [ Font.color (rgb255 163 179 222) ]
                                                    , text " but there is unsaved data belonging to "
                                                    , text expectedUserInfo.sub |> el [ Font.color (rgb255 163 179 222) ]
                                                    , text ". Either clear the local data and continue or log in to the other account."
                                                    ]
                                                , ViewComponents.textButton [] (Just ClickedDeleteLocalData) "Delete data"
                                                , ViewComponents.textButton [] (Just ClickedSignInToOtherAccount) "Sign in to the other account"
                                                ]

                                            Nothing ->
                                                [ paragraph [ Font.center ]
                                                    [ text "There is unsaved data on the local storage. Either import it to this account or delete it."
                                                    ]
                                                , ViewComponents.textButton [] (Just ClickedImportLocalData) "Import data"
                                                , ViewComponents.textButton [] (Just ClickedDeleteLocalData) "Delete data"
                                                ]
                                    }

                Verified _ ->
                    viewProgress model
                        |> View.Layout.layout
    in
    { title = "Synchronizing"
    , body = [ element ]
    }


viewExpiredAccessToken : Model -> String -> Element Msg
viewExpiredAccessToken model message =
    column
        [ centerX
        , centerY
        , spacing 20
        ]
        [ image
            [ width (px 36)
            , centerX
            ]
            { src = "assets/instruction-images/exception.svg"
            , description = "Loading animation"
            }
        , paragraph
            [ width shrink
            , centerX
            , centerY
            , Font.center
            , Font.size 28
            , Font.color color.font.error
            ]
            [ text "Your credentials are either expired or invalid. "
            , text message
            ]
        , link
            [ width (px 300)
            , centerX
            ]
            { label = ViewComponents.textButton [] Nothing "Sign in"
            , url = Auth0.login (Route.toUrl model.route)
            }
        , ViewComponents.textButton
            [ width (px 300)
            , centerX
            ]
            (Just ClickedContinueOffline)
            "Continue offline"
        ]


viewHttpError : Model -> GetError -> Element Msg
viewHttpError model error =
    case error of
        GetError.NetworkError ->
            Info.view
                { title = "Unable to connect to server"
                , icon =
                    { src = "assets/exception-orange.svg"
                    , description = "Alert icon"
                    }
                , elements =
                    [ ViewComponents.textButton [] (Just ClickedContinueOffline) "Continue offline"
                    ]
                }

        GetError.InvalidAccessToken message ->
            viewExpiredAccessToken model message

        _ ->
            View.ErrorScreen.view (GetError.toString error)


determineConflictResolution :
    { id : id
    , maybeLocal : Maybe (Maybe a)
    , maybeExpected : Maybe (Maybe a)
    , remoteActual : RemoteData.RemoteData GetError (Maybe a)
    , eq : a -> a -> Bool
    }
    -> ConflictResolution id a
determineConflictResolution { id, maybeLocal, maybeExpected, remoteActual, eq } =
    case RemoteData.toMaybe remoteActual of
        Just maybeActual ->
            case ( maybeLocal, maybeExpected, maybeActual ) of
                ( Just local, Just expected, Just actual ) ->
                    if eq local expected then
                        if eq local actual then
                            -- 1 1 1
                            DoNothing

                        else
                            -- 1 1 2
                            OverwriteLocal actual

                    else if eq local actual then
                        -- 1 2 1
                        OverwriteLocal actual

                    else if eq expected actual then
                        -- 1 2 2
                        OverwriteActual local

                    else
                        -- 1 2 3
                        ResolveManually
                            { localOrExpected = Both local expected
                            , maybeActual = maybeActual
                            }

                ( Just local, Just expected, Nothing ) ->
                    if eq local expected then
                        -- 1 1 0
                        DiscardLocal id

                    else
                        -- 1 2 0
                        ResolveManually
                            { localOrExpected = Both local expected
                            , maybeActual = maybeActual
                            }

                ( Just local, Nothing, Just actual ) ->
                    if eq local actual then
                        -- 1 0 1
                        OverwriteLocal actual

                    else
                        -- 1 0 2
                        ResolveManually
                            { localOrExpected = First local
                            , maybeActual = maybeActual
                            }

                ( Just local, Nothing, Nothing ) ->
                    -- 1 0 0
                    OverwriteActual local

                ( Nothing, Just expected, Just actual ) ->
                    if eq expected actual then
                        -- 0 1 1
                        DiscardActual id

                    else
                        -- 0 1 2
                        ResolveManually
                            { localOrExpected = Second expected
                            , maybeActual = maybeActual
                            }

                ( Nothing, Just expected, Nothing ) ->
                    -- 0 1 0
                    DiscardLocal id

                ( Nothing, Nothing, Just actual ) ->
                    -- 0 0 1
                    OverwriteLocal actual

                ( Nothing, Nothing, Nothing ) ->
                    -- 0 0 0
                    DoNothing

        Nothing ->
            DoNothing


resolveConflict :
    { overwriteLocal : a -> Model -> ( Model, Cmd msg )
    , overwriteExpected : a -> Model -> ( Model, Cmd msg )
    , overwriteActual : a -> Model -> ( Model, Cmd msg )
    , discardLocal : id -> Model -> ( Model, Cmd msg )
    , discardExpected : id -> Model -> ( Model, Cmd msg )
    , discardActual : id -> Model -> ( Model, Cmd msg )
    }
    -> Model
    -> ConflictResolution id a
    -> ( Model, Cmd msg )
resolveConflict { overwriteLocal, overwriteExpected, overwriteActual, discardLocal, discardExpected, discardActual } model conflictResolution =
    case conflictResolution of
        DoNothing ->
            ( model, Cmd.none )

        OverwriteLocal value ->
            Extra.Cmd.fold
                [ overwriteLocal value
                , overwriteExpected value
                ]
                model

        OverwriteActual value ->
            overwriteActual value model

        DiscardLocal id ->
            Extra.Cmd.fold
                [ discardLocal id
                , discardExpected id
                ]
                model

        DiscardActual id ->
            discardActual id model

        ResolveManually _ ->
            ( model, Cmd.none )

        Error error ->
            case error of
                GetError.InvalidAccessToken _ ->
                    ( withExpiredAccessToken model, GetError.consoleError error )

                _ ->
                    ( model, GetError.consoleError error )


viewProgress : Model -> Element Msg
viewProgress model =
    let
        draftsNeedingManualResolution =
            model.localDrafts
                |> Dict.keys
                |> List.sort
                |> List.filterMap
                    (\key ->
                        case
                            determineConflictResolution
                                { id = key
                                , maybeLocal = Dict.get key model.localDrafts
                                , maybeExpected = Dict.get key model.expectedDrafts
                                , remoteActual = Cache.get key model.actualDrafts
                                , eq = Draft.eq
                                }
                        of
                            ResolveManually record ->
                                Just record

                            _ ->
                                Nothing
                    )

        numberOfDraftsSaving =
            model.savingDrafts
                |> Dict.values
                |> List.filter isSaving
                |> List.length

        numberOfDraftsSaved =
            model.savingDrafts
                |> Dict.values
                |> List.filter (not << isSaving)
                |> List.length

        numberOfDraftsLoading =
            model.actualDrafts
                |> Cache.values
                |> List.filter RemoteData.isLoading
                |> List.length

        numberOfDraftsLoaded =
            model.actualDrafts
                |> Cache.values
                |> List.filter (not << RemoteData.isLoading)
                |> List.length

        numberOfSolutionsSaving =
            model.savingSolutions
                |> Dict.values
                |> List.filter isSaving
                |> List.length

        numberOfSolutionsSaved =
            model.savingSolutions
                |> Dict.values
                |> List.filter (not << isSaving)
                |> List.length

        blueprintsNeedingManualResolution =
            OneOrBoth.fromDicts model.localBlueprints model.expectedBlueprints
                |> List.sortBy (OneOrBoth.map .id >> OneOrBoth.any)
                |> List.filterMap
                    (\oneOrBoth ->
                        let
                            id =
                                OneOrBoth.any (OneOrBoth.map .id oneOrBoth)
                        in
                        case
                            determineConflictResolution
                                { id = id
                                , maybeLocal = OneOrBoth.first oneOrBoth
                                , maybeExpected = OneOrBoth.second oneOrBoth
                                , remoteActual = Cache.get id model.actualBlueprints
                                , eq = (==)
                                }
                        of
                            ResolveManually record ->
                                Just record

                            _ ->
                                Nothing
                    )

        numberOfBlueprintsSaving =
            model.savingBlueprints
                |> Dict.values
                |> List.filter isSaving
                |> List.length

        numberOfBlueprintsSaved =
            model.savingBlueprints
                |> Dict.values
                |> List.filter (not << isSaving)
                |> List.length

        numberOfBlueprintsLoading =
            model.actualBlueprints
                |> Cache.values
                |> List.filter RemoteData.isLoading
                |> List.length

        numberOfBlueprintsLoaded =
            model.actualBlueprints
                |> Cache.values
                |> List.filter (not << RemoteData.isLoading)
                |> List.length

        progressRow description current total =
            row [ width fill ]
                [ el [ alignLeft ] (text description)
                , [ String.fromInt current
                  , "/"
                  , String.fromInt total
                  ]
                    |> String.concat
                    |> text
                    |> el [ alignRight ]
                ]

        elements =
            [ column
                [ centerX, spacing 10 ]
                [ progressRow "Loading drafts: " numberOfDraftsLoaded (numberOfDraftsLoading + numberOfDraftsLoaded)
                , progressRow "Saving drafts: " numberOfDraftsSaved (numberOfDraftsSaving + numberOfDraftsSaved)
                , progressRow "Loading blueprints: " numberOfBlueprintsLoaded (numberOfBlueprintsLoading + numberOfBlueprintsLoaded)
                , progressRow "Saving blueprints: " numberOfBlueprintsSaved (numberOfBlueprintsSaving + numberOfBlueprintsSaved)
                , progressRow "Saving solutions: " numberOfSolutionsSaved (numberOfSolutionsSaving + numberOfSolutionsSaved)
                ]
            ]
    in
    case List.head draftsNeedingManualResolution of
        Just { localOrExpected, maybeActual } ->
            viewResolveConflict
                { id = OneOrBoth.any (OneOrBoth.map .id localOrExpected)
                , noun = "draft"
                , maybeLocal = OneOrBoth.first localOrExpected
                , maybeExpected = OneOrBoth.second localOrExpected
                , maybeActual = maybeActual
                , onOverwriteActual = ClickedDraftOverwriteActual
                , onOverwriteLocal = ClickedDraftOverwriteLocal
                , onDiscardLocal = ClickedDraftDiscardLocal
                , onDiscardActual = ClickedDraftDiscardActual
                }

        Nothing ->
            case List.head blueprintsNeedingManualResolution of
                Just { localOrExpected, maybeActual } ->
                    viewResolveConflict
                        { id = OneOrBoth.any (OneOrBoth.map .id localOrExpected)
                        , noun = "blueprint"
                        , maybeLocal = OneOrBoth.first localOrExpected
                        , maybeExpected = OneOrBoth.second localOrExpected
                        , maybeActual = maybeActual
                        , onOverwriteActual = ClickedBlueprintOverwriteActual
                        , onOverwriteLocal = ClickedBlueprintOverwriteLocal
                        , onDiscardLocal = ClickedBlueprintDiscardLocal
                        , onDiscardActual = ClickedBlueprintDiscardActual
                        }

                Nothing ->
                    viewLoading
                        { title = "Resolving unsaved data"
                        , elements = elements
                        }


viewResolveConflict :
    { id : String
    , noun : String
    , maybeLocal : Maybe a
    , maybeExpected : Maybe a
    , maybeActual : Maybe a
    , onOverwriteActual : a -> Msg
    , onOverwriteLocal : a -> Msg
    , onDiscardLocal : String -> Msg
    , onDiscardActual : String -> Msg
    }
    -> Element Msg
viewResolveConflict { id, noun, maybeLocal, maybeExpected, maybeActual, onOverwriteActual, onOverwriteLocal, onDiscardLocal, onDiscardActual } =
    let
        elements =
            case ( maybeLocal, maybeExpected, maybeActual ) of
                ( Just local, _, Just actual ) ->
                    [ paragraph [ Font.center ]
                        [ text "Your local changes on "
                        , text noun
                        , text " "
                        , text id
                        , text " have diverged from the server version. You need to choose which version you want to keep."
                        ]
                    , ViewComponents.textButton [] (Just (onOverwriteActual local)) "Keep my local changes"
                    , ViewComponents.textButton [] (Just (onOverwriteLocal actual)) "Keep the server changes"
                    ]

                ( Just local, _, Nothing ) ->
                    [ paragraph [ Font.center ]
                        [ text (String.Extra.toSentenceCase noun)
                        , text " "
                        , text id
                        , text " have been deleted from the server but there is still a copy stored locally. "
                        , text "You need to choose whether you want to keep it or not."
                        ]
                    , ViewComponents.textButton [] (Just (onOverwriteActual local)) "Keep it"
                    , ViewComponents.textButton [] (Just (onDiscardLocal id)) "Discard it"
                    ]

                ( Nothing, _, Just actual ) ->
                    [ paragraph [ Font.center ]
                        [ text (String.Extra.toSentenceCase noun)
                        , text " "
                        , text id
                        , text " have been deleted has been deleted locally, but there is a new version on the server. "
                        , text "You need to choose whether you want to keep the new server version or not."
                        ]
                    , ViewComponents.textButton [] (Just (onOverwriteLocal actual)) "Keep it"
                    , ViewComponents.textButton [] (Just (onDiscardActual id)) "Discard it"
                    ]

                ( Nothing, _, Nothing ) ->
                    [ paragraph [ Font.center ]
                        [ text "This is weird, it doesn't seem to be a conflict at all. Please refresh the page and report this issue."
                        ]
                    ]
    in
    Info.view
        { title = String.concat [ "Conflict in ", noun, " ", id ]
        , icon =
            { src = "assets/exception-orange.svg"
            , description = "Alert icon"
            }
        , elements = elements
        }


viewLoading :
    { title : String
    , elements : List (Element msg)
    }
    -> Element msg
viewLoading { title, elements } =
    column
        [ centerX
        , centerY
        , spacing 20
        , padding 40
        ]
        ([ paragraph
            [ Font.size 28
            , Font.center
            ]
            [ text title ]
         , image
            [ width (px 36)
            , centerX
            ]
            { src = "assets/spinner.svg"
            , description = "Loading spinner"
            }
         ]
            ++ elements
        )
