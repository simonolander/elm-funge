module InterceptorPage.Conflict.View exposing (view)

import Data.Blueprint as Blueprint
import Data.Draft as Draft
import Data.OneOrBoth as OneOrBoth exposing (OneOrBoth(..))
import Data.RemoteCache as RemoteCache
import Data.Session exposing (Session)
import Element exposing (..)
import Element.Font as Font
import Html exposing (Html)
import InterceptorPage.Conflict.Msg exposing (Msg(..), ObjectType(..))
import Json.Encode
import Maybe.Extra
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
        getOneOrBoth eq { maybeLocal, maybeExpected, maybeActual } =
            case maybeLocal of
                Just (Just local) ->
                    case maybeActual of
                        Just actual ->
                            if eq local actual then
                                Nothing

                            else if
                                Maybe.Extra.join maybeExpected
                                    |> Maybe.Extra.filter (\expected -> eq local expected || eq expected actual)
                                    |> Maybe.withDefault False
                            then
                                Nothing

                            else
                                Just (Both local actual)

                        Nothing ->
                            case maybeExpected of
                                Just (Just expected) ->
                                    if eq local expected then
                                        Nothing

                                    else
                                        Just (First local)

                                Just Nothing ->
                                    Nothing

                                Nothing ->
                                    Just (First local)

                Just Nothing ->
                    case maybeActual of
                        Just actual ->
                            if
                                Maybe.Extra.join maybeExpected
                                    |> Maybe.Extra.filter (eq actual)
                                    |> Maybe.withDefault False
                            then
                                Nothing

                            else
                                Just (Second actual)

                        Nothing ->
                            Nothing

                Nothing ->
                    Nothing

        toConflict objectType encode oneOrBoth =
            { id = OneOrBoth.map .id oneOrBoth |> OneOrBoth.any
            , oneOrBoth = OneOrBoth.map encode oneOrBoth
            , objectType = objectType
            }

        draftConflicts =
            RemoteCache.loadedTriplets session.drafts
                |> List.filterMap (getOneOrBoth Draft.eq)
                |> List.map (toConflict Draft Draft.encode)
                |> List.sortBy .id

        blueprintConflicts =
            RemoteCache.loadedTriplets session.blueprints
                |> List.filterMap (getOneOrBoth (==))
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
