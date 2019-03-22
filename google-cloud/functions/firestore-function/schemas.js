class AnySchema {
    validate(test, path = '') {
        return [];
    }
}


class ObjectSchema {
    constructor(schema = {}) {
        this.schema = Object.entries(schema);
    }

    validate(test, path = '') {
        if (typeof test !== 'object') {
            return [`${path} must be an object but was ${typeof test}`]
        }
        else {
            return [].concat(...this.schema.map(([key, value]) => value.validate(test[key], `${path}.${key}`)))
        }
    }
}

class NullableSchema {
    constructor(schema = new AnySchema) {
        this.schema = schema;
    }

    validate(test, path = '') {
        return test === null ? [] : this.schema.validate(test, path);
    }
}

class ExactSchema {
    constructor(value) {
        this.value = value;
    }

    validate(test, path = '') {
        if (test === value) {
            return []
        }
        else {
            return [`${path} must be exactly ${value} but was ${test}`]
        }
    }
}

class StringSchema {
    constructor({ minLength = 0, maxLength = 255 } = {}) {
        this.minLength = minLength;
        this.maxLength = maxLength;
    }

    validate(test, path = '') {
        if (typeof test !== 'string') {
            return [`${path} must be a string but was ${typeof test}`]
        }
        else if (typeof this.minLength === 'number' && test.length < this.minLength) {
            return [`${path} must be at least ${this.minLength} characters long`]
        }
        else if (typeof this.maxLength === 'number' && test.length > this.maxLength) {
            return [`${path} must be at most ${this.maxLength} characters long`]
        }
        else {
            return []
        }
    }
}

class IntegerSchema {
    constructor({ minValue, maxValue } = {}) {
        this.minValue = minValue;
        this.maxValue = maxValue;
    }

    validate(test, path = '') {
        if (typeof test !== 'number') {
            return [`${path} must be a number but was ${typeof test}`]
        }
        else if (!Number.isInteger(test)) {
            return [`${path} must be an integer but was ${test}`]
        }
        else if (typeof this.minValue === 'number' && test < this.minValue) {
            return [`${path} must be at least ${this.minValue} but was ${test}`]
        }
        else if (typeof this.maxValue === 'number' && test > this.maxValue) {
            return [`${path} must be at most ${this.maxValue} but was ${test}`]
        }
        else {
            return []
        }
    }
}

class ArraySchema {
    constructor({ each = new AnySchema } = {}) {
        this.each = each;
    }

    validate(testArray, path = '') {
        if (!Array.isArray(testArray)) {
            return [`${path} must be an array`]
        }
        else {
            return [].concat(testArray.map((test, index) => this.each.validate(test, `${path}[${index}]`)))
        }
    }
}

class AnyOfSchema {
    constructor({ anyOf = [] } = {}) {
        this.anyOf = anyOf;
    }

    validate(test, path = '') {
        const validates = this.anyOf.map((schema, index) => schema.validate(test, `${path}::${index}`));
        if (validates.some(messages => messages.length === 0)) {
            return [];
        }
        else {
            return [].concat(...validates);
        }
    }
}

class AllOfSchema {
    constructor({ allOf = [] } = {}) {
        this.allOf = allOf;
    }

    validate(test, path = '') {
        return [].concat(...this.allOf.map((schema, index) => schema.validate(test, `${path}::${index}`)));
    }
}

class EnumSchema extends StringSchema {
    constructor({ enums = [] } = {}) {
        super();
        this.enums = enums;
    }

    validate(test, path = '') {
        const validateSuper = super.validate(test, path);
        if (validateSuper.length !== 0) {
            return validateSuper;
        }
        else if (!this.enums.some(enumValue => enumValue === test)) {
            return [`${path} is ${enumValue} but must be one of [${this.enums.join(', ')}]`];
        }
        else {
            return [];
        }
    }
}

class DirectionSchema extends EnumSchema {
    constructor() {
        super({
            enums: [
                'Left',
                'Up',
                'Right',
                'Down'
            ]
        })
    }
}

class InstructionSchema extends AnyOfSchema {
    constructor() {
        super({
            anyOf: [
                new ObjectSchema({
                    tag: new EnumSchema({
                        enums: [
                            'NoOp',
                            'PopFromStack',
                            'JumpForward',
                            'Duplicate',
                            'Swap',
                            'Negate',
                            'Abs',
                            'Not',
                            'Increment',
                            'Decrement',
                            'Add',
                            'Subtract',
                            'Multiply',
                            'Divide',
                            'Equals',
                            'CompareLessThan',
                            'And',
                            'Or',
                            'XOr',
                            'Read',
                            'Print',
                            'Terminate',
                            'SendToBottom',
                        ]
                    })
                }),
                new ObjectSchema({
                    tag: new ExactSchema('PushToStack'),
                    value: new IntegerSchema
                }),
                new ObjectSchema({
                    tag: new ExactSchema('Branch'),
                    trueDirection: new DirectionSchema,
                    falseDirection: new DirectionSchema
                }),
                new ObjectSchema({
                    tag: new ExactSchema('Exception'),
                    exceptionMessage: new StringSchema
                }),
                new ObjectSchema({
                    tag: new ExactSchema('ChangeDirection'),
                    direction: new DirectionSchema
                }),
            ]
        });
    }
}

class InstructionToolSchema extends AnyOfSchema {
    constructor() {
        super({
            anyOf: [
                new ObjectSchema({
                    tag: new EnumSchema({
                        enums: [
                            'ChangeAnyDirection',
                            'BranchAnyDirection',
                            'PushValueToStack',
                        ]
                    })
                }),
                new ObjectSchema({
                    tag: new ExactSchema('JustInstruction'),
                    instruction: new InstructionSchema
                })
            ]
        })
    }
}

exports.levelSchema = new ObjectSchema({
    version: new IntegerSchema({ minValue: 0 }),
    id: new StringSchema,
    name: new StringSchema,
    description: new ArraySchema({
        each: new StringSchema
    }),
    io: new ObjectSchema({
        input: new ArraySchema({ each: new IntegerSchema }),
        output: new ArraySchema({ each: new IntegerSchema }),
    }),
    initialBoard: new ObjectSchema({
        width: new IntegerSchema({ minValue: 1 }),
        height: new IntegerSchema({ minValue: 1 }),
        instructions: new ArraySchema({
            each: new ObjectSchema({
                x: new IntegerSchema({ minValue: 0 }),
                y: new IntegerSchema({ minValue: 0 }),
                instruction: new InstructionSchema
            })
        })
    }),
    instructionTools: new ArraySchema({
        each: new InstructionToolSchema
    }),
    index: new IntegerSchema({ minLength: 0 }),
    chapter: new StringSchema,
    authorId: new NullableSchema(new StringSchema)
});