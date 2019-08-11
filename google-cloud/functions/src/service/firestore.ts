import {Firestore} from "@google-cloud/firestore";

const PROJECT_ID = "luminous-cubist-234816";
const firestore: Firestore = new Firestore({
    projectId: PROJECT_ID,
});

export type Collection
    = "users"
    | "drafts"
    | "levels"
    | "blueprints"
    | "solutions";

function get(collectionPath: Collection, parameters: { [s: string]: any, limit?: number, offset?: number }) {
    function fold(query: FirebaseFirestore.Query, [key, value]: [string, string | number]): FirebaseFirestore.Query {
        switch (key) {
            case "limit":
                return typeof value === "number"
                    ? query.limit(value)
                    : query;
            case "offset":
                return typeof value === "number"
                    ? query.offset(value)
                    : query;
            default:
                return query.where(key, "==", value);
        }
    }

    return Object.entries(parameters)
        .filter(([_, value]) => typeof value !== "undefined")
        .reduce(fold, firestore.collection(collectionPath))
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

function getById(collectionName: Collection): (id: string) => Promise<FirebaseFirestore.DocumentReference> {
    return async (id: string): Promise<FirebaseFirestore.DocumentReference> => firestore.collection(collectionName).doc(id);
}

/**
 * DRAFTS
 */

export const getDraftById = getById("drafts");

export async function getDrafts(parameters: { authorId: string, draftId?: string, levelId?: string }) {
    return get("drafts", parameters);
}

/**
 * LEVELS
 */

export const getLevelById = getById("levels");

export async function getLevels(parameters: { campaignId?: string, offset?: number, limit?: number }) {
    return get("levels", parameters);
}

/**
 * BLUEPRINTS
 */

export const getBlueprintById = getById("blueprints");

export async function getBlueprints(parameters: { authorId: string, offset?: number, limit?: number }) {
    return get("blueprints", parameters);
}

/**
 * SOLUTIONS
 */

export const getSolutionById = getById("solutions");

export async function getSolutions(parameters: { levelId?: string, authorId?: string, campaignId?: string }) {
    return get("solutions", parameters);
}
