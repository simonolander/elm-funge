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

const AUTH0_PEM =
    `-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5p0770GvIbSHccc1p02i
JSOX3qzora1iNRJJOooyvEjAmHZeRbiZlsaw86YvEcM9dllK9rVpj3TTE1E5MGJz
U3p7DzIBTfHE4f3K1gBlKiWuo/mUClEu5XRnPL36brfRfaRHe42rjzPFoZyjGZN4
QU4cqa13eQsTPRb+6OOYPiUPHhnTlfxr/0eGf4E8j3PQmsiCzjpQJkdgG2Kb8thH
iAdQvWb9plN5brxB4+7HXOVs+KqKRCrAVRJ6x4YggNFDjOxcSyvylpDZGY+OnRpI
/V1OD62pjU8pOzwE+TA3DBpdbmB+/EpINDotQ4R0LCXWwq04b/x7LwSouR09iMhF
+wIDAQAB
-----END PUBLIC KEY-----`;
const AUTH0_AUD = 'https://us-central1-luminous-cubist-234816.cloudfunctions.net';
const AUTH0_ISS = 'https://dev-253xzd4c.eu.auth0.com/';

const audience = AUTH0_AUD;
const issuer = AUTH0_ISS;
const pem = AUTH0_PEM;

const Exception = (status = 500, messages = 'An unknown error occurred') => ({
    status,
    messages: Array.isArray(messages) ? messages : [messages],
});

const verifyJwt = (req) => {
    const authorizationHeader = req.get('Authorization');
    if (typeof authorizationHeader !== 'string') {
        throw Exception(403, `Failed failed to extract authorization header, malformed header: ${authorizationHeader}`);
    }
    const splits = authorizationHeader.split(' ');
    if (splits.length !== 2) {
        throw Exception(403, `Failed failed to extract authorization header, malformed header: ${authorizationHeader}`);
    }
    const [type, token] = splits;
    if (type !== 'Bearer') {
        throw Exception(403, `Failed failed to extract authorization header, invalid type: ${type}`);
    }
    const tokenObject = jwt.verify(token, pem, {algorithm: 'RS256', audience: audience, issuer: issuer});
    const subject = tokenObject['sub'];
    if (typeof subject !== 'string') {
        throw Exception(403, `Failed to verify jwt, invalid subject: ${subject}`);
    }
    if (subject.length === 0) {
        throw Exception(403, `Failed to verify jwt, subject empty`);
    }
    return subject;
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

const validateObject = (object, schema) => {
    const errors = schema.validate(object);
    if (errors.length > 0) {
        throw Exception(400, errors);
    }
    return errors;
};

const getUser = async (subject) => {
    const usersCollection = firestore.collection('users');
    const querySnapshot = await usersCollection.where("subjectAuth0", "==", subject)
        .limit(1)
        .get();

    if (querySnapshot.empty) {
        const documentReference = await usersCollection.add({subjectAuth0: subject});
        return await documentReference.get();
    } else {
        return querySnapshot.docs[0];
    }
};

const getById = collectionName => async id => {
    const querySnapshot = await firestore.collection(collectionName)
        .where("id", "==", id)
        .limit(1)
        .get();

    if (querySnapshot.empty) {
        return null;
    }
    else {
        return querySnapshot.docs[0];
    }
};

const getDraft = getById("drafts");
const getLevel = getById("levels");
const getSolutions = getById("solutions");

exports.levels = async (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        if (req.method === 'GET') {
            const offset = Number.parseInt(req.query.offset || 0);
            const limit = Number.parseInt(req.query.limit || 50);
            const levels = await firestore.collection('levels')
                .offset(offset)
                .limit(limit)
                .get();
            return res.status(200)
                .send(levels.docs.map(doc => doc.data()));
        } else if (req.method === 'POST') {
            const {success, message, subject} = verifyJwt(req);
            if (!success) {
                return res.status(403)
                    .send({
                        status: 403,
                        messages: [message]
                    })
            }
            const level = validateObject(req.body, schemas.levelSchema);
            const documentReference = await firestore.collection("levels")
                .add({
                    ...level,
                    createdTime: new Date().getTime(),
                    authorId: subject
                });
            const documentSnapshot = await documentReference.get();
            return res.status(200)
                .send(documentSnapshot.data());
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

exports.userInfo = async (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        if (req.method === 'GET') {
            const subject = verifyJwt(req);
            const user = await getUser(subject);
            return res.status(200)
                .send(user.data());
        } else {
            return res.status(400)
                .send({
                    status: 400,
                    messages: [`Method not allowed: ${req.method}`],
                });
        }
    } catch (error) {
        console.error(error);
        const status = error.status || 500;
        const messages = error.messages || ['An unknown error occured'];
        return res.status(status)
            .send({status, messages})
    }
};

exports.drafts = async (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        const subject = verifyJwt(req);

        if (req.method === 'GET') {
            const user = await getUser(subject);
            const drafts = await firestore.collection("drafts")
                .where("authorId", "==", user.id)
                .get();

            return res.status(200)
                .send(drafts.docs.map(doc => doc.data()));
        } else if (req.method === 'POST') {
            const draft = validateObject(req.body, schemas.draftSchema);
            const user = getUser(subject);
            const existingDraft = getDraft(draft.id);
            await user;
            await existingDraft;
            if (existingDraft) {
                const existingDraftAuthorId = existingDraft.data().authorId;
                if (existingDraftAuthorId === user.id) {
                    const level = await getLevel(draft.levelId);
                    if (!level) {
                        return res.status(404)
                            .send({
                                status: 404,
                                messages: [`Level ${draft.levelId} not found`]
                            });
                    }
                    existingDraft.set({...draft, authorId: user.id});
                    return res.status(200).send();
                }
                else {
                    return res.status(401)
                        .send({
                            status: 401,
                            messages: [`User ${user.id} doesn't have the right to modify draft ${draft.id}`]
                        });
                }
            }
            else {
                const level = await getLevel(draft.levelId);
                if (!level) {
                    return res.status(404)
                        .send({
                            status: 404,
                            messages: [`Level ${draft.levelId} not found`]
                        });
                }
                firestore.collection("drafts")
                    .add({...draft, authorId: user.id});
                return res.status(200)
                    .send()
            }
        } else {
            return res.status(400)
                .send({
                    status: 400,
                    messages: [`Method not allowed: ${req.method}`],
                });
        }
    } catch (error) {
        console.error(error);
        const status = error.status || 500;
        const messages = error.messages || ['An unknown error occured'];
        return res.status(status)
            .send({status, messages})
    }
};

exports.highscore = async (req, res) => {
    try {
        if (accessControlRequest(req, res)) {
            return;
        }

        if (req.method === 'GET') {
            const { levelId } = validateObject(req.query, schemas.requestHighscore);
            const solutions = await firestore.collection("solutions")
                .where("levelId", "==", levelId)
                .get();

            const highscoreFields = ['numberOfSteps', 'numberOfInstructions'];
            const highscore = Object.entries(solutions.docs
                .map(doc => doc.data())
                .reduce((highscore, solution) => {
                highscoreFields.forEach(field => {
                    highscore[field][solution[field]] = highscore[field][solution[field]] + 1 || 1;
                });
                return highscore;
            }, highscoreFields.reduce((highscore, field) => {
                highscore[field] = {};
                return highscore;
            }, {}))).reduce((highscore, [field, counts]) => {
                highscore[field] = Object.entries(counts)
                    .map(([key, value]) => [parseInt(key), value]);
                return highscore;
            }, {});

            return res.status(200)
                .send(drafts.docs.map(doc => doc.data()));
        } else {
            return res.status(400)
                .send({
                    status: 400,
                    messages: [`Method not allowed: ${req.method}`],
                });
        }
    } catch (error) {
        console.error(error);
        const status = error.status || 500;
        const messages = error.messages || ['An unknown error occured'];
        return res.status(status)
            .send({status, messages})
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
