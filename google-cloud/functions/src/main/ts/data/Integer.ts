import {JsonDecoder} from "ts.data.json";

export const decoder = ({minValue, maxValue, fromString = false}: { minValue?: number, maxValue?: number, fromString?: boolean }): JsonDecoder.Decoder<number> => {
    const baseDecoder =
        fromString
            ? JsonDecoder.string.map(parseFloat)
            : JsonDecoder.number;
    const checkIsNotNaN = (value: number): JsonDecoder.Decoder<number> => !isNaN(value)
        ? JsonDecoder.constant(value)
        : JsonDecoder.fail(`${value} is not a number`);
    const checkIsFinite = (value: number): JsonDecoder.Decoder<number> => isFinite(value)
        ? JsonDecoder.constant(value)
        : JsonDecoder.fail(`${value} is not a finite number`);
    const checkIsInteger = (value: number): JsonDecoder.Decoder<number> => Number.isInteger(value)
        ? JsonDecoder.constant(value)
        : JsonDecoder.fail(`${value} is not an integer`);
    const checkMinValue = (value: number): JsonDecoder.Decoder<number> => typeof minValue === "undefined" || minValue <= value
        ? JsonDecoder.constant(value)
        : JsonDecoder.fail(`${value} is smaller than minimum value ${minValue}`);
    const checkMaxValue = (value: number): JsonDecoder.Decoder<number> => typeof maxValue === "undefined" || maxValue >= value
        ? JsonDecoder.constant(value)
        : JsonDecoder.fail(`${value} is greater than maximum value ${maxValue}`);

    return baseDecoder
        .then(checkIsNotNaN)
        .then(checkIsFinite)
        .then(checkIsInteger)
        .then(checkMinValue)
        .then(checkMaxValue);
};

export const nonNegativeDecoder: JsonDecoder.Decoder<number> = decoder({minValue: 0, maxValue: 16777216});
