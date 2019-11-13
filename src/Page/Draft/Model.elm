module Page.Draft.Model exposing (Model, State(..))

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
