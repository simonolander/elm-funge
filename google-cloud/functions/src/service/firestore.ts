import {Firestore} from "@google-cloud/firestore";
import {Blueprint} from "../data/Blueprint";
import {Level} from "../data/Level";
import {Solution} from "../data/Solution";

const PROJECT_ID = "luminous-cubist-234816";
const firestore: Firestore = new Firestore({
    projectId: PROJECT_ID,
});

const collectionPaths = {
    users: "users",
    drafts: "drafts",
    levels: "levels",
    blueprints: "blueprints",
    solutions: "solutions",
};

function get(collectionPath: string, parameters: { [s: string]: any, limit?: number, offset?: number }) {
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

    const collection = firestore.collection(collectionPath);
    return Object.entries(parameters)
        .filter(([_, value]) => typeof value !== "undefined")
        .reduce(fold, collection)
        .get();
}

export async function getUserBySubject(subject: string) {
    const usersCollection = firestore.collection(collectionPaths.users);
    return usersCollection.where("subjectAuth0", "==", subject)
        .limit(1)
        .get()
        .then(snapshot =>
            snapshot.empty
                ? usersCollection.add({subjectAuth0: subject})
                : usersCollection.doc(snapshot.docs[0].id));
}

function getById(collectionName: string): (id: string) => Promise<FirebaseFirestore.DocumentReference> {
    return async (id: string): Promise<FirebaseFirestore.DocumentReference> => firestore.collection(collectionName).doc(id);
}

/**
 * DRAFTS
 */

export const getDraftById = getById(collectionPaths.drafts);

export async function getDrafts(parameters: { authorId: string, draftId?: string, levelId?: string }) {
    return get(collectionPaths.drafts, parameters);
}

/**
 * LEVELS
 */

export const getLevelById = getById(collectionPaths.levels);

export async function getLevels(parameters: { campaignId?: string, offset?: number, limit?: number }) {
    return get(collectionPaths.levels, parameters);
}

export async function addLevel(level: Level) {
    return firestore.collection(collectionPaths.levels)
        .add(level);
}

/**
 * BLUEPRINTS
 */

export const getBlueprintById = getById(collectionPaths.blueprints);

export async function getBlueprints(parameters: { authorId: string, offset?: number, limit?: number }) {
    return get(collectionPaths.blueprints, parameters);
}

export async function addBlueprint(blueprint: Blueprint) {
    return firestore.collection(collectionPaths.blueprints)
        .add(blueprint);
}

/**
 * SOLUTIONS
 */

export const getSolutionById = getById(collectionPaths.solutions);

export async function getSolutions(parameters: { levelId?: string, authorId?: string, campaignId?: string }) {
    return get(collectionPaths.solutions, parameters);
}

export async function addSolution(solution: Solution) {
    return firestore.collection(collectionPaths.solutions)
        .add(solution);
}
