module InterceptorPage.Conflict.View exposing (view)

import Data.Blueprint as Blueprint
import Data.Draft as Draft
import Data.OneOrBoth as OneOrBoth exposing (OneOrBoth(..))
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Html exposing (Html)
import InterceptorPage.Conflict.Msg exposing (Msg(..), ObjectType(..))
import Json.Encode
import Resource.ModifiableResource as Resource
import Resource.ResourceUpdater exposing (getConflictResolution)
import String.Extra
import View.Info as Info
import View.Layout exposing (layout)
import ViewComponents


type alias Conflict =
    { id : String
    , oneOrBoth : OneOrBoth Json.Encode.Value
    , objectType : ObjectType
    }


view : Session -> Maybe ( String, Html Msg )
view session =
    let
        toConflict objectType encode oneOrBoth =
            { id = OneOrBoth.map .id oneOrBoth |> OneOrBoth.any
            , oneOrBoth = OneOrBoth.map encode oneOrBoth
            , objectType = objectType
            }

        draftConflicts =
            Resource.loadedTriplets session.drafts
                |> List.filterMap (getConflictResolution (==) >> toConflict)
                |> List.map (toConflict Draft Draft.encode)
                |> List.sortBy .id

        blueprintConflicts =
            Resource.loadedTriplets session.blueprints
                |> List.filterMap (getConflictResolution (==) >> toConflict)
                |> List.map (toConflict Blueprint Blueprint.encode)
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
viewConflict { id, oneOrBoth, objectType } =
    let
        noun =
            case objectType of
                Draft ->
                    "draft"

                Blueprint ->
                    "blueprint"
    in
    Info.view
        { title = String.concat [ "Conflict in ", noun, " ", id ]
        , icon =
            { src = "assets/exception-orange.svg"
            , description = "Alert icon"
            }
        , elements =
            case oneOrBoth of
                Both local actual ->
                    [ paragraph [ Font.center ]
                        [ text "Your local changes on "
                        , text noun
                        , text " "
                        , text id
                        , text " have diverged from the server version. You need to choose which version you want to keep."
                        ]
                    , ViewComponents.textButton [] (Just (ClickedKeepLocal id objectType)) "Keep my local changes"
                    , ViewComponents.textButton [] (Just (ClickedKeepServer id objectType)) "Keep the server changes"
                    ]

                First local ->
                    [ paragraph [ Font.center ]
                        [ text (String.Extra.toSentenceCase noun)
                        , text " "
                        , text id
                        , text " have been deleted from the server but there is still a copy stored locally. "
                        , text "You need to choose whether you want to keep it or not."
                        ]
                    , ViewComponents.textButton [] (Just (ClickedKeepLocal id objectType)) "Keep it"
                    , ViewComponents.textButton [] (Just (ClickedKeepServer id objectType)) "Discard it"
                    ]

                Second actual ->
                    [ paragraph [ Font.center ]
                        [ text (String.Extra.toSentenceCase noun)
                        , text " "
                        , text id
                        , text " have been deleted has been deleted locally, but there is a new version on the server. "
                        , text "You need to choose whether you want to keep the new server version or not."
                        ]
                    , ViewComponents.textButton [] (Just (ClickedKeepServer id objectType)) "Keep it"
                    , ViewComponents.textButton [] (Just (ClickedKeepLocal id objectType)) "Discard it"
                    ]
        }
