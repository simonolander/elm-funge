const Firestore = require('@google-cloud/firestore');
const jwt = require('jsonwebtoken');
const schemas = require('./schemas');


const PROJECT_ID = 'luminous-cubist-234816';
const COLLECTION_NAME = 'numbers';
const firestore = new Firestore({
    projectId: PROJECT_ID
});

const AMAZON_COGNITO_PEM =
    `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnw9jJN1VszovM0H9M0SA
QB2MvXCGRsdz0WaApl5VYOrCrXOcHsvDzZ4CDup+NJvRMLFbLK8fUMqrZPnY5Qnp
keF6ZSiX+axHF8531+puvsDeDyYOeX/Ysjaftw5aq9bHcSkEbH5zqKWifClfbFvO
0cS/bY9T5+astotPH8n87KMG/KMcZOVtOcOhYusb/oIrct40t3z18VfPB+kMQtUK
4ekt0yf1J543kAY+nBjkyie9/bMyBhjGXJZcly4fRimhatrUgSn/S4BWgPyIzVWP
6ywgwfDPVQzVgyWQrz5tSLRX5dPLe2zZYkdnTVFWBxynebpg5ZPUoQk+J08/lPLy
0wIDAQAB
-----END PUBLIC KEY-----`;

const AMAZON_COGNITO_AUD = '1mu4rr1moo02tobp2m4oe80pn8';
const AMAZON_COGNITO_ISS = 'https://cognito-idp.us-east-1.amazonaws.com/us-east-1_BbVWFzVcU';

const verifyJwt = (req) => {
    try {
        const authorizationHeader = req.get('Authorization');
        if (typeof authorizationHeader !== 'string') {
            return {
                success: false,
                message: `Failed failed to extract authorization header, malformed header: ${authorizationHeader}`
            };
        }
        const splits = authorizationHeader.split(' ');
        if (splits.length !== 2) {
            return {
                success: false,
                message: `Failed failed to extract authorization header, malformed header: ${authorizationHeader}`
            };
        }
        const [type, token] = splits;
        if (type !== 'Bearer') {
            return {
                success: false,
                message: `Failed failed to extract authorization header, invalid type: ${type}`
            };
        }
        const tokenObject = jwt.verify(token, AMAZON_COGNITO_PEM, {algorithm: 'RS256'});
        if (tokenObject.token_use !== 'id') {
            return {
                success: false,
                message: `Failed to verify jwt, invalid token use: ${tokenObject.token_use}`
            };
        }
        if (tokenObject.aud !== AMAZON_COGNITO_AUD) {
            return {
                success: false,
                message: `Failed to verify jwt, invalid audience: ${tokenObject.aud}`
            };
        }
        if (tokenObject.iss !== AMAZON_COGNITO_ISS) {
            return {
                success: false,
                message: `Failed to verify jwt, invalid issuer: ${tokenObject.iss}`
            };
        }
        const username = tokenObject['cognito:username'];
        if (typeof username !== 'string') {
            return {
                success: false,
                message: `Failed to verify jwt, invalid cognito:username: ${username}`
            };
        }
        if (typeof username.length === 0) {
            return {
                success: false,
                message: `Failed to verify jwt, invalid cognito:username: ${username}`
            };
        }
        return {
            success: true,
            username,
            email: tokenObject.email
        };
    } catch (e) {
        console.error(e);
        return {
            success: false,
            message: e.message
        };
    }
};

const accessControlRequest = (req, res) => {
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'GET');
        res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
        res.set('Access-Control-Max-Age', '3600');
        res.status(204).send('');
        return true;
    }
    return false;
};

const objectHasErrors = (object, schema, res) => {
    const errors = schema.validate(object);
    if (errors.length > 0) {
        res.status(400)
            .send({
                status: 400,
                messages: errors
            });
        return true;
    }
    return false;
};

exports.levels = (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        if (req.method === 'GET') {
            const offset = Number.parseInt(req.query.offset || 0);
            const limit = Number.parseInt(req.query.limit || 50);
            return firestore.collection('levels')
                .offset(offset)
                .limit(limit)
                .get()
                .then(collection =>
                    res.status(200)
                        .send(collection.docs.map(doc => doc.data())))
        } else if (req.method === 'POST') {
            const {success, message, username} = verifyJwt(req);
            if (!success) {
                return res.status(403)
                    .send({
                        status: 403,
                        messages: [message]
                    })
            }
            const level = req.body;
            const errors = schemas.levelSchema.validate(level);
            if (errors.length > 0) {
                return res.status(400)
                    .send({
                        status: 400,
                        messages: errors
                    });
            }

            return firestore.collection("levels")
                .add({
                    ...level,
                    createdTime: new Date().getTime(),
                    authorId: username
                })
                .then(doc => res.status(200).send(doc))
                .catch(error => {
                    console.error(error);
                    return res.status(500)
                        .send({
                            status: 500,
                            messages: ["An error occured when saving the level to the database"],
                            error
                        })
                });
        } else {
            return res.status(400)
                .send({
                    status: 400,
                    messages: [`Method not allowed: ${req.method}`],
                });
        }
    } catch (error) {
        console.error(error);
        return res.status(500)
            .send({
                status: 500,
                messages: ["An error occured when performing the request"],
                error
            });
    }
};

exports.level = (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        if (req.method === 'GET') {
            const id = Number.parseInt(req.query.offset || 0);
            const limit = Number.parseInt(req.query.limit || 50);
            return firestore.collection('levels')
                .offset(offset)
                .limit(limit)
                .get()
                .then(collection =>
                    res.status(200)
                        .send(collection.docs.map(doc => doc.data())))
        } else if (req.method === 'POST') {
            const {success, message, username} = verifyJwt(req);
            if (!success) {
                return res.status(403)
                    .send({
                        status: 403,
                        messages: [message]
                    })
            }
            const level = req.body;
            const errors = schemas.levelSchema.validate(level);
            if (errors.length > 0) {
                return res.status(400)
                    .send({
                        status: 400,
                        messages: errors
                    });
            }

            return firestore.collection("levels")
                .add({
                    ...level,
                    createdTime: new Date().getTime(),
                    authorId: username
                })
                .then(doc => res.status(200).send(doc))
                .catch(error => {
                    console.error(error);
                    return res.status(500)
                        .send({
                            status: 500,
                            messages: ["An error occured when saving the level to the database"],
                            error
                        })
                });
        } else {
            return res.status(400)
                .send({
                    status: 400,
                    messages: [`Method not allowed: ${req.method}`],
                });
        }
    } catch (error) {
        console.error(error);
        return res.status(500)
            .send({
                status: 500,
                messages: ["An error occured when performing the request"],
                error
            });
    }
};

exports.scores = (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        switch (req.method) {
            case 'GET':
                if (objectHasErrors(req.query, schemas.getScoresRequest, res)) {
                    return;
                }
                const { levelId } = req.query;
                return firestore.collection('scores')
                    .
                break;
            default:
                return res.status(400)
                    .send({
                        status: 400,
                        messages: [`Method not allowed: ${req.method}`],
                    });
        }

        if (req.method === 'GET') {
            const offset = Number.parseInt(req.query.offset || 0);
            const limit = Number.parseInt(req.query.limit || 50);
            return firestore.collection('levels')
                .offset(offset)
                .limit(limit)
                .get()
                .then(collection =>
                    res.status(200)
                        .send(collection.docs.map(doc => doc.data())))
        } else if (req.method === 'POST') {
            const {success, message, username} = verifyJwt(req);
            if (!success) {
                return res.status(403)
                    .send({
                        status: 403,
                        messages: [message]
                    })
            }
            const level = req.body;
            const errors = schemas.levelSchema.validate(level);
            if (errors.length > 0) {
                return res.status(400)
                    .send({
                        status: 400,
                        messages: errors
                    });
            }

            return firestore.collection("levels")
                .add({
                    ...level,
                    createdTime: new Date().getTime(),
                    authorId: username
                })
                .then(doc => res.status(200).send(doc))
                .catch(error => {
                    console.error(error);
                    return res.status(500)
                        .send({
                            status: 500,
                            messages: ["An error occured when saving the level to the database"],
                            error
                        })
                });
        } else {
        }
    } catch (error) {
        console.error(error);
        return res.status(500)
            .send({
                status: 500,
                messages: ["An error occured when performing the request"],
                error
            });
    }
};

exports.numbers = (req, res) => {
    if (req.method === 'DELETE') throw 'not yet built';
    if (req.method === 'POST') {
        // store/insert a new document
        const data = (req.body) || {};
        const number = Number.parseInt(data.number);
        const createdTime = new Date().getTime();
        return firestore.collection(COLLECTION_NAME)
            .add({createdTime, number, data})
            .then(doc => {
                return res.status(200).send(doc);
            }).catch(err => {
                console.error(err);
                return res.status(404).send({error: 'unable to store', err});
            });
    }
    // read/retrieve an existing document by id
    if (!(req.query && req.query.id)) {
        return res.status(404).send({error: 'No Id'});
    }
    const id = req.query.id.replace(/[^a-zA-Z0-9]/g, '').trim();
    if (!(id && id.length)) {
        return res.status(404).send({error: 'Empty Id'});
    }
    return firestore.collection(COLLECTION_NAME)
        .doc(id)
        .get()
        .then(doc => {
            if (!(doc && doc.exists)) {
                return res.status(404).send({error: 'Unable to find the document'});
            }
            const data = doc.data();
            return res.status(200).send(data);
        }).catch(err => {
            console.error(err);
            return res.status(404).send({error: 'Unable to retrieve the document'});
        });
};
