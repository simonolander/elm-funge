module Page.Draft.Model exposing (Model, State(..), init)

import Data.DraftId exposing (DraftId)


type State
    = Editing
    | Deleting
    | Importing
        { importData : String
        , errorMessage : Maybe String
        }


type alias Model =
    { draftId : DraftId
    , state : State
    , error : Maybe String
    , selectedInstructionToolIndex : Maybe Int
    }


init : DraftId -> Model
init draftId =
    { draftId = draftId
    , state = Editing
    , error = Nothing
    , selectedInstructionToolIndex = Nothing
    }
