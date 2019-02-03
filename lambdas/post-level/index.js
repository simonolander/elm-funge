const AWS = require('aws-sdk')
const RDS = new AWS.RDSDataService({ apiVersion: '2018-08-01' })

function validateDirection(direction) {
    if (['Left', 'Up', 'Right', 'Down'].every(dir => dir !== direction)) {
        throw new Error(`not a valid direction: ${direction}`)
    }
}

function validateInteger(integer) {
    if (!Number.isInteger(integer)) {
        throw new Error(`not a valid integer: ${integer}`)
    }
}

function validateString(string) {
    if (typeof string !== 'string') {
        throw new Error(`not a valid string: ${string}`)
    }
}

const validateArray = validator => array => {
    if (!Array.isArray(array)) {
        throw new Error(`not a valid array: ${array}`)
    }
    array.forEach(validator)
}

const validateObject = validators => object => {
    if (typeof object !== 'object') {
        throw new Error(`not a valid object: ${object}`)
    }

    Object.entries(validators).forEach((path, validator) => {
        validator(object[path])
    })
}

function validateInstruction(instruction) {
    validateObject(instruction)
    validateString(instruction.tag)

    switch (instruction.tag) {
        case 'NoOp':
            break;
        case 'ChangeDirection':
            validateDirection(instruction.direction)
            break;
        case 'PushToStack':
            validateInteger(instruction.value)
            break;
        case 'PopFromStack':
            break;
        case 'JumpForward':
            break;
        case 'Duplicate':
            break;
        case 'Swap':
            break;
        case 'Negate':
            break;
        case 'Abs':
            break;
        case 'Not':
            break;
        case 'Increment':
            break;
        case 'Decrement':
            break;
        case 'Add':
            break;
        case 'Subtract':
            break;
        case 'Multiply':
            break;
        case 'Divide':
            break;
        case 'Equals':
            break;
        case 'CompareLessThan':
            break;
        case 'And':
            break;
        case 'Or':
            break;
        case 'XOr':
            break;
        case 'Read':
            break;
        case 'Print':
            break;
        case 'Branch':
            validateDirection(instruction.trueDirection)
            validateDirection(instruction.falseDirection)
            break;
        case 'Terminate':
            break;
        case 'SendToBottom':
            break;
        case 'Exception':
            validateString(instruction.exceptionMessage)
            break;
        default:
            throw new Error(`not a valid tag: ${tag}`)
    }
}

function validateBoardV0(board) {
    validateArray(board)

    if (board.length < 1) {
        throw new Error('board cannot be empty')
    }

    board.forEach(row => {
        if (!Array.isArray(row)) {
            throw new Error('board is not an array of arrays')
        }
    })

    const width = board[0].length;
    if (width < 1) {
        throw new Error('board cannot be empty')
    }

    board.forEach(row => {
        if (row.length !== width) {
            throw new Error('all board rows must have the same length')
        }
    })

    board.forEach(row => {
        row.forEach(instruction => {
            validateInstruction(instruction)
        })
    })
}

function validateBoardV1(board) {
    if (typeof board.board !== 'object') {
        throw new Error('board.board is not an object')
    }

    validateboardV0(board.board)
}

function validateBoard(board) {
    if (typeof board !== 'object') {
        throw new Error('board is not an object')
    }

    if (typeof board.version === 'undefined') {
        validateboardV0(board)
    }
    else if (board.version === 1) {
        validateBoardV1(board)
    }
    else {
        throw new Error('unknown board.version: ' + board.version)
    }
}

function validateLevelV1(level) {
    validateString(level.id);
    validateString(level.name);
    validateArray(level.description)
    level.description.forEach(validateString)
    validateObject(level.io)
    validateArray(level.io.input)
    level.io.input.forEach(validateInteger)
    validateArray(level.io.output)
    level.io.output.forEach(validateInteger)
    validateBoard(level.board)
    validateArray(level.instructionTools)
    level.instructionTools.forEach(validateInstructionTool);
}

function validateLevel(level) {
    if (typeof level !== 'object') {
        throw new Error('level is not an object')
    }

    if (typeof level.version === 1) {
        validateLevelV1(level)
    }
    else {
        throw new Error('unknown level.version: ' + level.version)
    }
}

function insertBoard(board) {
    const
}

function insertLevel(level) {
    const initialBoardId = insertBoard(level.initialBoard.board)
    const insertLevelSql = `
        insert into levels set 
            name = ${level.name},
            external_id = ${level.id},
            initial_board_id = ${initialBoardId};
        select last_insert_id() id;
        `
    const levelId = executeSql(insertLevelSql)
    const insertInputsSql =
        'insert into level_inputs (level_id, value, ordinal) values '
        + level.io.input.map((value, index) => `(${levelId}, ${value}, ${index})`).join(', ')
    const insertOutputsSql =
        'insert into level_outputs (level_id, value, ordinal) values '
        + level.io.outputs.map((value, index) => `(${levelId}, ${value}, ${index})`).join(', ')
    const insertDescriptionsSql =
        'insert into level_descriptions (level_id, description, ordinal) values '
        + level.descriptions.map((value, index) => `(${levelId}, ${value.replace("'", "")}, ${index})`).join(', ')
    const insertEverythingSql = [insertInputsSql, insertOutputsSql, insertDescriptionsSql].join(";")
    return executeSql(insertEverythingSql)
}

exports.handler = async (event, context) => {
    try {
        const query =
            'insert into boards (width, height) values (3, 4); select last_insert_id() id;';
        data = await RDS.executeSql(
            {
                awsSecretStoreArn: 'arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL',
                dbClusterOrInstanceArn: 'arn:aws:rds:us-east-1:361301349588:cluster:efng',
                sqlStatements: query,
                database: 'efng'
            }
        ).promise()

        console.log(JSON.stringify(data, null, 2))

        return 'done'

    } catch (e) {
        console.log(e)
    }
}