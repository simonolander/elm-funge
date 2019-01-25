const AWS = require('aws-sdk')
const RDS = new AWS.RDSDataService({ apiVersion: '2018-08-01' })

exports.handler = async (event, context) => {
    try {
        const query =
            'select * from levels'
            + ' join level_descriptions on levels.id = level_descriptions.level_id'
            + ' join level_inputs on levels.id = level_inputs.level_id'
            + ' join level_outputs on levels.id = level_outputs.level_id'
            + ' join level_instruction_tools on levels.id = level_instruction_tools.level_id'
            + ' join boards on boards.id = levels.initial_board_id;';
        data = await RDS.executeSql(
            {
                awsSecretStoreArn: 'arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL',
                dbClusterOrInstanceArn: 'arn:aws:rds:us-east-1:361301349588:cluster:efng',
                sqlStatements: query,
                database: 'efng'
            }
        ).promise();

        console.log(JSON.stringify(data, null, 2))

        return 'done'

    } catch (e) {
        console.log(e)
    }
}