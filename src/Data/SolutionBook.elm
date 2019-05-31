module Data.SolutionBook exposing (SolutionBook, decoder, empty, encode, loadFromLocalStorage, localStorageResponse, saveToLocalStorage, withSolutionId, withSolutionIds)

import Basics.Extra exposing (flip)
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Data.SolutionId as SolutionId exposing (SolutionId)
import Extra.Decode
import Extra.Encode
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage
import Set exposing (Set)


type alias SolutionBook =
    { levelId : LevelId
    , solutionIds : Set SolutionId
    }


empty : LevelId -> SolutionBook
empty levelId =
    { levelId = levelId
    , solutionIds = Set.empty
    }


withSolutionId : SolutionId -> SolutionBook -> SolutionBook
withSolutionId solutionId levelSolutions =
    { levelSolutions
        | solutionIds = Set.insert solutionId levelSolutions.solutionIds
    }


withSolutionIds : Set SolutionId -> SolutionBook -> SolutionBook
withSolutionIds solutionIds levelSolutions =
    { levelSolutions
        | solutionIds = Set.union levelSolutions.solutionIds solutionIds
    }



-- JSON


encode : SolutionBook -> Encode.Value
encode levelSolutions =
    Encode.object
        [ ( "levelId", LevelId.encode levelSolutions.levelId )
        , ( "solutionIds", Extra.Encode.set SolutionId.encode levelSolutions.solutionIds )
        ]


decoder : Decode.Decoder SolutionBook
decoder =
    Decode.field "levelId" LevelId.decoder
        |> Decode.andThen
            (\levelId ->
                Decode.field "solutionIds" (Extra.Decode.set SolutionId.decoder)
                    |> Decode.andThen
                        (\solutionIds ->
                            Decode.succeed
                                { levelId = levelId
                                , solutionIds = solutionIds
                                }
                        )
            )



-- LOCAL STORAGE


localStorageKey : LevelId -> Ports.LocalStorage.Key
localStorageKey levelId =
    String.join "." [ "levels", levelId, "solutionBook" ]


saveToLocalStorage : SolutionId -> LevelId -> Cmd msg
saveToLocalStorage solutionId levelId =
    let
        key =
            localStorageKey levelId

        value =
            SolutionId.encode solutionId
    in
    Ports.LocalStorage.storagePushToSet ( key, value )


loadFromLocalStorage : LevelId -> Cmd msg
loadFromLocalStorage levelId =
    let
        key =
            localStorageKey levelId
    in
    Ports.LocalStorage.storageGetItem key


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult LevelId Decode.Error SolutionBook)
localStorageResponse ( key, value ) =
    case String.split "." key of
        "levels" :: levelId :: "solutionBook" :: [] ->
            let
                localStorageDecoder =
                    SolutionId.decoder
                        |> Extra.Decode.set
                        |> Decode.map (flip withSolutionIds (empty levelId))
                        |> Decode.nullable
                        |> Decode.map (Maybe.withDefault (empty levelId))
            in
            value
                |> Decode.decodeValue localStorageDecoder
                |> RequestResult.constructor levelId
                |> Just

        _ ->
            Nothing
