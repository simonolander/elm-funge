module InterceptorPage.Conflict.View exposing (view)

import Data.Blueprint as Blueprint
import Data.Draft as Draft
import Data.OneOrBoth as OneOrBoth exposing (OneOrBoth(..))
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Html exposing (Html)
import InterceptorPage.Conflict.Msg exposing (Msg(..))
import Json.Encode
import Service.Blueprint.BlueprintService as BlueprintService
import Service.Draft.DraftService as DraftService
import Service.ResourceType as ResourceType exposing (ResourceType)
import String.Extra
import View.Info as Info
import View.Layout exposing (layout)
import ViewComponents


type alias Conflict =
    { id : String
    , oneOrBoth : OneOrBoth Json.Encode.Value
    , resourceType : ResourceType
    , keepLocalMessage : Msg
    , keepServerMessage : Msg
    }


view : Session -> Maybe ( String, Html Msg )
view session =
    let
        toConflict resourceType encode keepLocalMessage keepServerMessage oneOrBoth =
            let
                id =
                    OneOrBoth.map .id oneOrBoth
                        |> OneOrBoth.any
            in
            { id = id
            , oneOrBoth = OneOrBoth.map encode oneOrBoth
            , resourceType = resourceType
            , keepLocalMessage = keepLocalMessage id
            , keepServerMessage = keepServerMessage id
            }

        draftConflicts =
            DraftService.getConflicts session
                |> List.map
                    (toConflict
                        ResourceType.Draft
                        Draft.encode
                        ClickedKeepLocalDraft
                        ClickedKeepServerDraft
                    )
                |> List.sortBy .id

        blueprintConflicts =
            BlueprintService.getConflicts session
                |> List.map
                    (toConflict
                        ResourceType.Blueprint
                        Blueprint.encode
                        ClickedKeepLocalBlueprint
                        ClickedKeepServerBlueprint
                    )
                |> List.sortBy .id

        conflicts =
            List.concat
                [ draftConflicts
                , blueprintConflicts
                ]
    in
    List.head conflicts
        |> Maybe.map viewConflict
        |> Maybe.map layout
        |> Maybe.map (Tuple.pair "Conflict")


viewConflict : Conflict -> Element Msg
viewConflict c =
    let
        noun =
            ResourceType.toLower c.resourceType
    in
    Info.view
        { title = String.concat [ "Conflict in ", noun, " ", c.id ]
        , icon =
            { src = "assets/exception-orange.svg"
            , description = "Alert icon"
            }
        , elements =
            case c.oneOrBoth of
                Both local actual ->
                    [ paragraph [ Font.center ]
                        [ text "Your local changes on "
                        , text noun
                        , text " "
                        , text c.id
                        , text " have diverged from the server version. You need to choose which version you want to keep."
                        ]
                    , ViewComponents.textButton [] (Just c.keepLocalMessage) "Keep my local changes"
                    , ViewComponents.textButton [] (Just c.keepServerMessage) "Keep the server changes"
                    ]

                First local ->
                    [ paragraph [ Font.center ]
                        [ text (String.Extra.toSentenceCase noun)
                        , text " "
                        , text c.id
                        , text " have been deleted from the server but there is still a copy stored locally. "
                        , text "You need to choose whether you want to keep it or not."
                        ]
                    , ViewComponents.textButton [] (Just c.keepLocalMessage) "Keep it"
                    , ViewComponents.textButton [] (Just c.keepServerMessage) "Discard it"
                    ]

                Second actual ->
                    [ paragraph [ Font.center ]
                        [ text (String.Extra.toSentenceCase noun)
                        , text " "
                        , text c.id
                        , text " have been deleted has been deleted locally, but there is a new version on the server. "
                        , text "You need to choose whether you want to keep the new server version or not."
                        ]
                    , ViewComponents.textButton [] (Just c.keepServerMessage) "Keep it"
                    , ViewComponents.textButton [] (Just c.keepLocalMessage) "Discard it"
                    ]
        }
