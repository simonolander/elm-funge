module View.Instruction exposing (view)

import Data.Instruction exposing (Instruction(..))
import Element exposing (..)
import Element.Background as Background
import Html.Attributes
import ViewComponents exposing (instructionButton)


view : { instruction : Instruction, onClick : Maybe msg, indicated : Bool, disabled : Bool } -> Element msg
view params =
    let
        attributes =
            if params.disabled then
                let
                    backgroundColor =
                        case params.instruction of
                            Exception _ ->
                                rgb 0.1 0 0

                            _ ->
                                rgb 0.15 0.15 0.15
                in
                [ Background.color backgroundColor
                , htmlAttribute (Html.Attributes.style "cursor" "not-allowed")
                , mouseOver []
                ]

            else
                []

        onPress =
            if params.disabled then
                Nothing

            else
                params.onClick
    in
    instructionButton attributes onPress params.instruction
