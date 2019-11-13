module Page.Draft.Msg exposing (Msg(..))

import Data.Instruction exposing (Instruction)
import Data.InstructionTool exposing (InstructionTool)
import Data.Position exposing (Position)


type Msg
    = ImportDataChanged String
    | Import String
    | ImportOpen
    | ImportClosed
    | EditUndo
    | EditRedo
    | EditClear
    | ClickedDeleteDraft
    | ClickedConfirmDeleteDraft
    | ClickedCancelDeleteDraft
    | InstructionToolReplaced Int InstructionTool
    | InstructionToolSelected Int
    | InstructionPlaced Position Instruction
