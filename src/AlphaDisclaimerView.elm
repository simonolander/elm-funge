module AlphaDisclaimerView exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes
import Model exposing (..)
import ViewComponents


view : Html Msg
view =
    let
        titleView =
            text "EFNG"
                |> el
                    [ centerX
                    , Font.size 32
                    ]

        alphaDisclaimerView =
            paragraph []
                [ text "This puzzle game is in early alpha. "
                , text "Not all the features are available, things will change, and there might be bugs. "
                , text "Your progress will be automatically saved for now, but may be unavailable in future releases. "
                , text "There are also not really any instructions. "
                ]

        tinyInstructionsView =
            paragraph []
                [ text "Every level requires you to write a program to solve. The program must output the expected output and terminate." ]

        featureListView =
            column
                []
                [ text "The current features are: "
                , text "  - ~20 levels"
                , text "  - ~16 instructions"
                , text "  - Save solved levels and last edit to local storage"
                , text "  - Import and export your boards"
                ]

        sourceCodeView =
            paragraph []
                [ text "You can browse the source "
                , newTabLink
                    [ Font.color (rgb 0.5 0.5 1)
                    ]
                    { url = "https://github.com/simonolander/elm-funge"
                    , label = text "here"
                    }
                , text ". If you'd like, leave suggestions and reports in the "
                , newTabLink
                    [ Font.color (rgb 0.5 0.5 1)
                    ]
                    { url = "https://github.com/simonolander/elm-funge/issues"
                    , label = text "issues page"
                    }
                , text "."
                ]

        playButtonView =
            ViewComponents.textButton [] (Just (NavigationMessage (GoToBrowsingLevels Nothing))) "I got it, let's play"
    in
    column
        [ padding 100
        , spacing 20
        ]
        [ titleView
        , alphaDisclaimerView
        , tinyInstructionsView
        , featureListView
        , sourceCodeView
        , playButtonView
        ]
        |> layout
            [ Background.color (rgb 0 0 0)
            , width fill
            , height fill
            , Font.family
                [ Font.monospace
                ]
            , Font.color (rgb 1 1 1)
            ]
