module View.Board exposing (view)

import Array
import Data.Board exposing (Board)
import Data.BoardInstruction exposing (BoardInstruction)
import Data.Position exposing (Position)
import Element exposing (..)
import Set exposing (Set)
import View.Instruction


view :
    { board : Board
    , onClick : Maybe (BoardInstruction -> msg)
    , selectedPosition : Maybe Position
    , disabledPositions : List Position
    }
    -> Element msg
view params =
    let
        disabledSet =
            params.disabledPositions
                |> List.map (\{ x, y } -> ( x, y ))
                |> Set.fromList

        viewRow rowIndex boardRow =
            let
                viewCell columnIndex instruction =
                    let
                        position =
                            { x = columnIndex, y = rowIndex }

                        boardInstruction =
                            { instruction = instruction
                            , position = position
                            }

                        indicated =
                            Maybe.map ((==) position) params.selectedPosition
                                |> Maybe.withDefault False

                        disabled =
                            Set.member ( position.x, position.y ) disabledSet

                        onClick =
                            Maybe.map ((|>) boardInstruction) params.onClick
                    in
                    View.Instruction.view
                        { instruction = instruction
                        , onClick = onClick
                        , indicated = indicated
                        , disabled = disabled
                        }
            in
            boardRow
                |> Array.indexedMap viewCell
                |> Array.toList
                |> row [ spacing 10 ]
    in
    params.board
        |> Array.indexedMap viewRow
        |> Array.toList
        |> column
            [ spacing 10
            , width fill
            , height fill
            , padding 10
            ]
