import {JsonDecoder} from "ts.data.json";

export const decoder = function ({minValue, maxValue, fromString = false} : { minValue?: number, maxValue?: number, fromString?: boolean}): JsonDecoder.Decoder<number> {
    const baseDecoder =
        fromString
            ? JsonDecoder.string.map(parseFloat)
            : JsonDecoder.number;
    const checkIsNotNaN = function (value: number): JsonDecoder.Decoder<number> {
        return !isNaN(value)
            ? JsonDecoder.constant(value)
            : JsonDecoder.fail(`${value} is not a number`);
    };
    const checkIsFinite = function (value: number): JsonDecoder.Decoder<number> {
        return isFinite(value)
            ? JsonDecoder.constant(value)
            : JsonDecoder.fail(`${value} is not a finite number`);
    };
    const checkIsInteger = function (value: number): JsonDecoder.Decoder<number> {
        return Number.isInteger(value)
            ? JsonDecoder.constant(value)
            : JsonDecoder.fail(`${value} is not an integer`);
    };
    const checkMinValue = function (value: number): JsonDecoder.Decoder<number> {
        return typeof minValue === "undefined" || minValue <= value
            ? JsonDecoder.constant(value)
            : JsonDecoder.fail(`${value} is smaller than minimum value ${minValue}`);
    };
    const checkMaxValue = function (value: number): JsonDecoder.Decoder<number> {
        return typeof maxValue === "undefined" || maxValue >= value
            ? JsonDecoder.constant(value)
            : JsonDecoder.fail(`${value} is greater than maximum value ${maxValue}`);
    };

    return baseDecoder
        .then(checkIsNotNaN)
        .then(checkIsFinite)
        .then(checkIsInteger)
        .then(checkMinValue)
        .then(checkMaxValue)
};

export const nonNegativeDecoder: JsonDecoder.Decoder<number> = decoder({minValue: 0, maxValue: 16777216});
