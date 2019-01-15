const AWS = require('aws-sdk')
const RDS = new AWS.RDSDataService({ apiVersion: '2018-08-01' })

exports.handler = async (event, context) => {

    try {

        const params = {
            awsSecretStoreArn: 'arn:aws:secretsmanager:us-east-1:361301349588:secret:efng/aurora-uD1DRL',
            dbClusterOrInstanceArn: 'arn:aws:rds:us-east-1:361301349588:cluster:efng',
            sqlStatements: `SELECT * FROM test`,
            database: 'efng'
        }

        let data = await RDS.executeSql(params).promise()

        console.log(JSON.stringify(data, null, 2))

        return 'done'

    } catch (e) {
        console.log(e)
    }
}