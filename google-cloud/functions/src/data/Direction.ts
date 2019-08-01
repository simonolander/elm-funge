import {JsonDecoder} from "ts.data.json";

export type Direction
    = "Left"
    | "Right"
    | "Up"
    | "Down";

export const decoder: JsonDecoder.Decoder<Direction> = JsonDecoder.oneOf(
    [
        JsonDecoder.isExactly("Left"),
        JsonDecoder.isExactly("Right"),
        JsonDecoder.isExactly("Up"),
        JsonDecoder.isExactly("Down"),
    ],
    "Direction",
);
