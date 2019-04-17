module Data.Session exposing (Session, getDraftAndLevel, getLevelDrafts, getToken, init, withDraft, withDrafts, withLevel, withLevels, withUser)

import Browser.Navigation exposing (Key)
import Data.AuthorizationToken exposing (AuthorizationToken)
import Data.Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Data.Level exposing (Level)
import Data.LevelId exposing (LevelId)
import Data.User as User exposing (User)
import Dict exposing (Dict)


type alias Session =
    { key : Key
    , user : User
    , levels : Maybe (Dict LevelId Level)
    , drafts : Maybe (Dict DraftId Draft)
    }


init : Key -> Session
init key =
    { key = key
    , user = User.guest
    , levels = Nothing
    , drafts = Nothing
    }


withUser : User -> Session -> Session
withUser user session =
    { session
        | user = user
    }


withLevels : List Level -> Session -> Session
withLevels levels session =
    { session
        | levels =
            levels
                |> List.map (\level -> ( level.id, level ))
                |> Dict.fromList
                |> Just
    }


withLevel : Level -> Session -> Session
withLevel level session =
    { session
        | levels =
            Maybe.withDefault Dict.empty session.levels
                |> Dict.insert level.id level
                |> Just
    }


withDrafts : List Draft -> Session -> Session
withDrafts drafts session =
    { session
        | drafts =
            drafts
                |> List.map (\draft -> ( draft.id, draft ))
                |> Dict.fromList
                |> Just
    }


withDraft : Draft -> Session -> Session
withDraft draft session =
    { session
        | drafts =
            Maybe.withDefault Dict.empty session.drafts
                |> Dict.insert draft.id draft
                |> Just
    }


getToken : Session -> Maybe AuthorizationToken
getToken =
    .user >> User.getToken


getLevelDrafts : LevelId -> Session -> List Draft
getLevelDrafts levelId session =
    session.drafts
        |> Maybe.map Dict.values
        |> Maybe.withDefault []
        |> List.filter (\draft -> draft.levelId == levelId)


getDraftAndLevel : DraftId -> Session -> Maybe ( Draft, Level )
getDraftAndLevel draftId session =
    case Maybe.andThen (Dict.get draftId) session.drafts of
        Just draft ->
            case Maybe.andThen (Dict.get draft.levelId) session.levels of
                Just level ->
                    Just ( draft, level )

                Nothing ->
                    Nothing

        Nothing ->
            Nothing
