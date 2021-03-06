module Data.Campaign exposing (Campaign, decoder, empty, encode, loadFromLocalStorage, localStorageResponse, saveToLocalStorage, withLevelId, withoutLevelId)

import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.LevelId as LevelId exposing (LevelId)
import Data.RequestResult as RequestResult exposing (RequestResult)
import Json.Decode as Decode
import Json.Encode as Encode
import Ports.LocalStorage as LocalStorage


type alias Campaign =
    { id : CampaignId
    , levelIds : List LevelId
    }


empty : CampaignId -> Campaign
empty campaignId =
    { id = campaignId
    , levelIds = []
    }


withLevelId : LevelId -> Campaign -> Campaign
withLevelId levelId campaign =
    { campaign
        | levelIds = levelId :: campaign.levelIds
    }


withoutLevelId : LevelId -> Campaign -> Campaign
withoutLevelId levelId campaign =
    { campaign
        | levelIds =
            campaign.levelIds
                |> List.filter ((/=) levelId)
    }



-- LOCAL STORAGE


localStorageKey : CampaignId -> LocalStorage.Key
localStorageKey campaignId =
    String.join "." [ "campaigns", campaignId ]


loadFromLocalStorage : CampaignId -> Cmd msg
loadFromLocalStorage campaignId =
    LocalStorage.storageGetItem (localStorageKey campaignId)


saveToLocalStorage : Campaign -> Cmd msg
saveToLocalStorage campaign =
    LocalStorage.storageSetItem
        ( localStorageKey campaign.id
        , encode campaign
        )


localStorageResponse : ( String, Encode.Value ) -> Maybe (RequestResult CampaignId Decode.Error (Maybe Campaign))
localStorageResponse ( key, value ) =
    case String.split "." key of
        "campaigns" :: campaignId :: [] ->
            value
                |> Decode.decodeValue (Decode.nullable decoder)
                |> RequestResult.constructor campaignId
                |> Just

        _ ->
            Nothing



-- JSON


encode : Campaign -> Encode.Value
encode campaign =
    Encode.object
        [ ( "version", Encode.int 1 )
        , ( "id", CampaignId.encode campaign.id )
        , ( "levelIds", Encode.list LevelId.encode campaign.levelIds )
        ]


decoder : Decode.Decoder Campaign
decoder =
    Decode.field "version" Decode.int
        |> Decode.andThen
            (\version ->
                case version of
                    1 ->
                        Decode.field "id" Decode.string
                            |> Decode.andThen
                                (\id ->
                                    Decode.field "levelIds" (Decode.list LevelId.decoder)
                                        |> Decode.andThen
                                            (\levelIds ->
                                                Decode.succeed
                                                    { id = id
                                                    , levelIds = levelIds
                                                    }
                                            )
                                )

                    _ ->
                        Decode.fail ("Unknown version: " ++ String.fromInt version)
            )
