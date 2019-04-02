module Data.DraftId exposing (DraftId(..), toString, urlParser)

import Url.Parser exposing (Parser)


type DraftId
    = DraftId String


urlParser : Parser (DraftId -> a) a
urlParser =
    Url.Parser.custom "DRAFT ID" (\str -> Just (DraftId str))


toString : DraftId -> String
toString (DraftId id) =
    id
