const AWS = require('aws-sdk')
const RDS = new AWS.RDSDataService({ apiVersion: '2018-08-01' })


function insertBoard(board) {

}

function insertLevel(level) {
    const initialBoardId = insertBoard(level.initialBoard)
    const insertLevelSql = `
        insert into levels set 
            name = ${level.name},
            external_id = ${level.id},
            initial_board_id = ${initialBoardId}
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