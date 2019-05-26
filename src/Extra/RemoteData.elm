module Extra.RemoteData exposing (successes)

import Maybe.Extra
import RemoteData exposing (RemoteData)


successes : List (RemoteData error value) -> List value
successes list =
    List.map RemoteData.toMaybe list
        |> Maybe.Extra.values
