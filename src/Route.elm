module Route exposing (Route(..), back, fromUrl, link, pushUrl, replaceUrl)

import Browser.Navigation as Navigation
import Data.DraftId as DraftId
import Element
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s)


type Route
    = Home
    | Levels
    | EditDraft DraftId.DraftId
    | ExecuteDraft DraftId.DraftId


fromUrl : Url -> Maybe Route
fromUrl url =
    { url
        | path = Maybe.withDefault "" url.fragment
        , fragment = Nothing
    }
        |> Parser.parse parser


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

                Levels ->
                    [ "levels" ]

                EditDraft draftId ->
                    [ "drafts", DraftId.toString draftId ]

                ExecuteDraft draftId ->
                    [ "drafts", DraftId.toString draftId, "execute" ]
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
        , Parser.map Levels (s "levels")
        , Parser.map EditDraft (s "drafts" </> DraftId.urlParser)
        , Parser.map ExecuteDraft (s "drafts" </> DraftId.urlParser </> s "execute")
        ]
