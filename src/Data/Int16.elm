module Data.Int16 exposing (Int16, abs, add, constructor, decoder, divide, encode, fromString, isLessThan, multiply, negate, one, power, subtract, toString, zero)

import Basics.Extra exposing (flip)
import Json.Decode as Decode
import Json.Encode as Encode


type Int16
    = Int16 Int


zero : Int16
zero =
    constructor 0


one : Int16
one =
    constructor 1


add : Int16 -> Int16 -> Int16
add (Int16 a) (Int16 b) =
    constructor ((+) a b)


subtract : Int16 -> Int16 -> Int16
subtract (Int16 a) (Int16 b) =
    constructor ((-) a b)


multiply : Int16 -> Int16 -> Int16
multiply (Int16 a) (Int16 b) =
    constructor ((*) a b)


divide : Int16 -> Int16 -> Int16
divide (Int16 a) (Int16 b) =
    constructor ((//) a b)


power : Int16 -> Int16 -> Int16
power (Int16 a) (Int16 b) =
    constructor ((^) a b)


abs : Int16 -> Int16
abs (Int16 a) =
    constructor (Basics.abs a)


negate : Int16 -> Int16
negate (Int16 a) =
    constructor (Basics.negate a)


isLessThan : Int16 -> Int16 -> Bool
isLessThan (Int16 a) (Int16 b) =
    (<) a b



-- STRING


toString : Int16 -> String
toString (Int16 a) =
    String.fromInt a


fromString : String -> Maybe Int16
fromString =
    String.toInt >> Maybe.map constructor



-- JSON


encode : Int16 -> Encode.Value
encode (Int16 int) =
    Encode.int int


decoder : Decode.Decoder Int16
decoder =
    Decode.map constructor Decode.int



-- INTERNAL


constructor : Int -> Int16
constructor int =
    int
        |> (+) (2 ^ 15)
        |> modBy (2 ^ 16)
        |> flip (-) (2 ^ 15)
        |> Int16
