module Update.HighScore exposing
    ( getHighScoreByLevelId
    , gotLoadHighScoreByLevelIdResponse
    , loadHighScoreByLevelId
    )

import Data.GetError exposing (GetError)
import Data.HighScore exposing (HighScore)
import Data.LevelId exposing (LevelId)
import Data.Session exposing (Session)
import Debug exposing (todo)
import RemoteData exposing (RemoteData)
import Update.SessionMsg exposing (SessionMsg)



-- LOAD


loadHighScoreByLevelId : LevelId -> Session -> ( Session, Cmd SessionMsg )
loadHighScoreByLevelId levelId session =
    todo ""


gotLoadHighScoreByLevelIdResponse : LevelId -> Result GetError HighScore -> Session -> ( Session, Cmd SessionMsg )
gotLoadHighScoreByLevelIdResponse levelId result session =
    todo ""



-- GETTER


getHighScoreByLevelId : LevelId -> Session -> RemoteData GetError HighScore
getHighScoreByLevelId levelId session =
    todo ""



-- PRIVATE


gotHighScore : LevelId -> Maybe HighScore -> Session -> ( Session, Cmd SessionMsg )
gotHighScore levelId maybeHighScore session =
    todo ""
