module HistoryTest exposing (all)

import Data.History as History
import Expect
import Fuzz
import Test exposing (..)



-- Check out http://package.elm-lang.org/packages/elm-community/elm-test/latest to learn more about testing in Elm!


all : Test
all =
    describe "Testing history data structure"
        [ fuzz Fuzz.int
            "back(singleton(a)) should be singleton(a)"
            (\a -> Expect.equal (History.singleton a) (History.back (History.singleton a)))
        , fuzz Fuzz.int
            "current(singleton(a)) should be a"
            (\a -> Expect.equal a (History.current (History.singleton a)))
        , fuzz Fuzz.int
            "first(singleton(a)) should be a"
            (\a -> Expect.equal a (History.first (History.singleton a)))
        , fuzz Fuzz.int
            "forward(singleton(a)) should be singleton(a)"
            (\a -> Expect.equal (History.singleton a) (History.forward (History.singleton a)))
        , fuzz Fuzz.int
            "fromList([a]) should be just(singleton(a))"
            (\a -> Expect.equal (Just (History.singleton a)) (History.fromList [ a ]))
        , fuzz Fuzz.int
            "hasFuture(singleton(a)) should be false"
            (\a -> Expect.equal False (History.hasFuture (History.singleton a)))
        , fuzz Fuzz.int
            "hasPast(singleton(a)) should be false"
            (\a -> Expect.equal False (History.hasPast (History.singleton a)))
        , fuzz Fuzz.int
            "last(singleton(a)) should be a"
            (\a -> Expect.equal a (History.last (History.singleton a)))
        , fuzz2 Fuzz.int
            Fuzz.int
            "map((+) b, singleton(a)) should be singleton(a + b)"
            (\a b -> Expect.equal (History.singleton (a + b)) (History.map ((+) b) (History.singleton a)))
        , fuzz2 Fuzz.int
            Fuzz.int
            "push(b, singleton(a)) should be toEnd(fromList([a, b]))"
            (\a b -> Expect.equal (Maybe.map History.toEnd (History.fromList [ a, b ])) (Just (History.push b (History.singleton a))))
        , fuzz Fuzz.int
            "size(singleton(a)) should be 1"
            (\a -> Expect.equal 1 (History.size (History.singleton a)))
        , fuzz Fuzz.int
            "toBeginning(singleton(a)) should be singleton(a)"
            (\a -> Expect.equal (History.singleton a) (History.toBeginning (History.singleton a)))
        , fuzz Fuzz.int
            "toEnd(singleton(a)) should be singleton(a)"
            (\a -> Expect.equal (History.singleton a) (History.toEnd (History.singleton a)))
        , fuzz Fuzz.int
            "toList(singleton(a)) should be [a]"
            (\a -> Expect.equal [ a ] (History.toList (History.singleton a)))
        , fuzz2 Fuzz.int
            Fuzz.int
            "update((+) b, singleton(a)) should be singleton(a + b)"
            (\a b -> Expect.equal (History.singleton (a + b)) (History.update ((+) b) (History.singleton a)))
        ]
