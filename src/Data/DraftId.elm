module Data.DraftId exposing (DraftId(..), decoder, encode, toString, urlParser)

import Json.Decode as Decode
import Json.Encode as Encode
import Url.Parser exposing (Parser)


type DraftId
    = DraftId String


urlParser : Parser (DraftId -> a) a
urlParser =
    Url.Parser.custom "DRAFT ID" (\str -> Just (DraftId str))


toString : DraftId -> String
toString (DraftId id) =
    id



-- JSON


encode : DraftId -> Encode.Value
encode =
    toString >> Encode.string


decoder : Decode.Decoder DraftId
decoder =
    Decode.map DraftId Decode.string
