import {Firestore} from "@google-cloud/firestore"
import {Solution} from "../data/Solution";
import {Draft} from "../data/Draft";
import {Level} from "../data/Level";
import Query = FirebaseFirestore.Query;

const PROJECT_ID = "luminous-cubist-234816";
const firestore: Firestore = new Firestore({
    projectId: PROJECT_ID
});

function get(collectionPath: string, parameters: {[s: string]: any}) {
    const collection: Query = firestore.collection(collectionPath);
    return Object.entries(parameters)
        .filter(([_, value]) => typeof value !== "undefined")
        .reduce((query, [key, value]) => query.where(key, "==", value), collection)
        .get();
}

export async function getUserBySubject(subject: string) {
    const usersCollection = firestore.collection("users");
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

export async function getDrafts(parameters: { authorId: string, draftId?: string, levelId?: string }) {
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
    let query = firestore.collection("levels")
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
    return firestore.collection("levels")
        .add(level)
}

/**
 * BLUEPRINTS
 */

export const getBlueprintById = getById("blueprints");

export async function getBlueprints(parameters: { authorId: string, offset?: number, limit?: number }) {
    const {authorId, offset, limit} = parameters;
    let query = firestore.collection("blueprints")
        .where("authorId", "==", authorId);

    if (typeof offset !== "undefined") {
        query = query.offset(offset);
    }

    if (typeof limit !== "undefined") {
        query = query.offset(limit);
    }

    return query.get();
}

export async function addBlueprint(blueprint: Level) {
    return firestore.collection("blueprints")
        .add(blueprint)
}

export async function getBlueprintDocument(id: string) {
    return firestore.collection("blueprints")
        .doc(id);
}

/**
 * SOLUTIONS
 */

export const getSolutionById = getById("solutions");

export async function getSolutions(parameters: { levelId?: string, authorId?: string, campaignId?: string }) {
    return get('solutions', parameters);
}

export async function addSolution(solution: Solution) {
    return firestore.collection("solutions")
        .add(solution);
}
