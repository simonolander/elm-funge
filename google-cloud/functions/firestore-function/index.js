const Firestore = require('@google-cloud/firestore');
const schemas = require('./schemas');
const PROJECT_ID = 'luminous-cubist-234816';
const COLLECTION_NAME = 'numbers';
const firestore = new Firestore({
  projectId: PROJECT_ID
});

exports.levels = (req, res) => {
  try {
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
    }
    else if (req.method === 'POST') {
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
          createdTime: new Date().getTime()
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
    }
    else {
      return res.status(400)
        .send({
          status: 400,
          messages: [`Method not allowed: ${req.method}`],
        });
    }
  }
  catch (error) {
    console.error(error);
    return res.status(500)
      .send({
        status: 500,
        messages: ["An error occured when performing the request"],
        error
      });
  }
}

exports.numbers = (req, res) => {
  if (req.method === 'DELETE') throw 'not yet built';
  if (req.method === 'POST') {
    // store/insert a new document
    const data = (req.body) || {};
    const number = Number.parseInt(data.number);
    const createdTime = new Date().getTime();
    return firestore.collection(COLLECTION_NAME)
      .add({ createdTime, number, data })
      .then(doc => {
        return res.status(200).send(doc);
      }).catch(err => {
        console.error(err);
        return res.status(404).send({ error: 'unable to store', err });
      });
  }
  // read/retrieve an existing document by id
  if (!(req.query && req.query.id)) {
    return res.status(404).send({ error: 'No Id' });
  }
  const id = req.query.id.replace(/[^a-zA-Z0-9]/g, '').trim();
  if (!(id && id.length)) {
    return res.status(404).send({ error: 'Empty Id' });
  }
  return firestore.collection(COLLECTION_NAME)
    .doc(id)
    .get()
    .then(doc => {
      if (!(doc && doc.exists)) {
        return res.status(404).send({ error: 'Unable to find the document' });
      }
      const data = doc.data();
      return res.status(200).send(data);
    }).catch(err => {
      console.error(err);
      return res.status(404).send({ error: 'Unable to retrieve the document' });
    });
};
