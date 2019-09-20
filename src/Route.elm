module Route exposing (Route(..), back, fromUrl, link, pushUrl, replaceUrl, toUrl)

import Basics.Extra exposing (flip)
import Browser.Navigation as Navigation
import Data.CampaignId as CampaignId exposing (CampaignId)
import Data.DraftId as DraftId
import Data.LevelId as LevelId
import Element
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s)


type Route
    = Home
    | Campaign CampaignId (Maybe LevelId.LevelId)
    | Campaigns
    | EditDraft DraftId.DraftId
    | ExecuteDraft DraftId.DraftId
    | Blueprints (Maybe LevelId.LevelId)
    | Blueprint LevelId.LevelId
    | Credits
    | NotFound


fromUrl : Url -> Maybe Route
fromUrl url =
    { url
        | path = Maybe.withDefault "" url.fragment
        , fragment = Nothing
    }
        |> Parser.parse parser


toUrl : Route -> Maybe Url
toUrl =
    toString >> Url.fromString


link : List (Element.Attribute msg) -> Element.Element msg -> Route -> Element.Element msg
link attributes label route =
    Element.link
        attributes
        { url = toString route
        , label = label
        }


toString : Route -> String
toString route =
    let
        pieces =
            case route of
                Home ->
                    []

                Campaign campaignId Nothing ->
                    [ "campaign", campaignId ]

                Campaign campaignId (Just levelId) ->
                    [ "campaign", campaignId, "level", levelId ]

                Campaigns ->
                    [ "campaigns" ]

                Credits ->
                    [ "credits" ]

                EditDraft draftId ->
                    [ "drafts", DraftId.toString draftId ]

                ExecuteDraft draftId ->
                    [ "drafts", DraftId.toString draftId, "execute" ]

                Blueprints Nothing ->
                    [ "blueprints" ]

                Blueprints (Just levelId) ->
                    [ "blueprints", levelId ]

                Blueprint levelId ->
                    [ "blueprints", levelId, "edit" ]

                NotFound ->
                    [ "notFound" ]
    in
    "/#" ++ String.join "/" pieces


pushUrl : Navigation.Key -> Route -> Cmd msg
pushUrl key route =
    Navigation.pushUrl key (toString route)


replaceUrl : Navigation.Key -> Route -> Cmd msg
replaceUrl key route =
    Navigation.replaceUrl key (toString route)


back : Navigation.Key -> Cmd msg
back key =
    Navigation.back key 1


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map (flip Campaign Nothing) (s "campaign" </> CampaignId.urlParser)
        , Parser.map Campaigns (s "campaigns")
        , Parser.map (\campaignId levelId -> Campaign campaignId (Just levelId)) (s "campaign" </> CampaignId.urlParser </> s "level" </> LevelId.urlParser)
        , Parser.map EditDraft (s "drafts" </> DraftId.urlParser)
        , Parser.map ExecuteDraft (s "drafts" </> DraftId.urlParser </> s "execute")
        , Parser.map (Blueprints Nothing) (s "blueprints")
        , Parser.map (Blueprints << Just) (s "blueprints" </> LevelId.urlParser)
        , Parser.map Blueprint (s "blueprints" </> LevelId.urlParser </> s "edit")
        , Parser.map Credits (s "credits")
        ]
