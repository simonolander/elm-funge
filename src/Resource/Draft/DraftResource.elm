module Resource.Draft.DraftResource exposing (DraftResource)

import Data.Draft exposing (Draft)
import Data.DraftId exposing (DraftId)
import Resource.Resource exposing (Resource)


type alias DraftResource =
    Resource DraftId Draft {}
