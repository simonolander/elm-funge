module Page.Blueprint.Msg exposing (Msg(..))

import Data.BoardInstruction exposing (BoardInstruction)
import Data.InstructionTool exposing (InstructionTool)


type Msg
    = ChangedWidth String
    | ChangedHeight String
    | ChangedInput String
    | ChangedOutput String
    | InstructionToolSelected Int
    | InstructionToolReplaced Int InstructionTool
    | InstructionToolEnabled Int
    | InitialInstructionPlaced BoardInstruction
