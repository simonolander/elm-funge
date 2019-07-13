import {Firestore} from '@google-cloud/firestore'
import {Solution} from "../data/Solution";
import {Draft} from "../data/Draft";
import {Level} from "../data/Level";

const PROJECT_ID = 'luminous-cubist-234816';
const firestore: Firestore = new Firestore({
    projectId: PROJECT_ID
});

export async function getUserBySubject(subject: string) {
    const usersCollection = firestore.collection('users');
    return usersCollection.where("subjectAuth0", "==", subject)
        .limit(1)
        .get()
        .then(snapshot =>
            snapshot.empty
                ? usersCollection.add({subjectAuth0: subject})
                : usersCollection.doc(snapshot.docs[0].id));
}

function getById(collectionName: string): (id: string) => Promise<FirebaseFirestore.QuerySnapshot> {
    return async function (id: string): Promise<FirebaseFirestore.QuerySnapshot> {
        return firestore.collection(collectionName)
            .where("id", "==", id)
            .limit(1)
            .get()
    }
}

/**
 * DRAFTS
 */

export const getDraftById = getById("drafts");

export async function getDrafts(parameters: { authorId: string, draftId?: string, levelId?: string}) {
    let query = firestore.collection("drafts")
        .where("authorId", "==", parameters.authorId);
    if (typeof parameters.draftId !== "undefined") {
        query = query.where("id", "==", parameters.draftId);
    }
    if (typeof parameters.levelId !== "undefined") {
        query = query.where("levelId", "==", parameters.levelId);
    }
    return query.get();
}

export async function addDraft(draft: Draft) {
    return firestore.collection("drafts")
        .add(draft);
}

export async function getDraftDocument(id: string) {
    return firestore.collection("drafts")
        .doc(id);
}

/**
 * LEVELS
 */

export const getLevelById = getById("levels");

export async function getLevels(parameters: { campaignId: string, offset?: number, limit?: number }) {
    const {campaignId, offset, limit} = parameters;
    let query = firestore.collection('levels')
        .where("campaignId", "==", campaignId);

    if (typeof offset !== "undefined") {
        query = query.offset(offset);
    }

    if (typeof limit !== "undefined") {
        query = query.offset(limit);
    }

    return query.get();
}


export async function addLevel(level: Level) {
    return firestore.collection('levels')
        .add(level)
}

/**
 * Solutions
 */

export const getSolutionById = getById("solutions");

export async function getSolutions({levelId, authorId}: { levelId: string, authorId?: string }) {
    let query = firestore.collection("solutions")
        .where("levelId", "==", levelId);

    if (typeof authorId !== "undefined") {
        query = query.where("authorId", "==", authorId);
    }

    return query.get();
}

export async function addSolution(solution: Solution) {
    return firestore.collection("solutions")
        .add(solution);
}