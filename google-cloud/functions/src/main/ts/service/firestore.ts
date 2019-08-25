import {Firestore} from "@google-cloud/firestore";
import {JsonDecoder, Ok} from "ts.data.json";
import * as Blueprint from "../data/Blueprint";
import * as Draft from "../data/Draft";
import * as Level from "../data/Level";
import * as Solution from "../data/Solution";

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

function get<T>(collectionPath: Collection, parameters: { [s: string]: any, limit?: number, offset?: number }, decoder: JsonDecoder.Decoder<T>): Promise<T[]> {
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
        .get()
        .then(ref => ref.docs.map(doc => decoder.decode(doc.data())))
        .then(results => {
            const successes: T[] = [];
            const errors: string[] = [];
            for (const result of results) {
                if (result instanceof Ok) {
                    successes.push(result.value);
                } else {
                    errors.push(result.error);
                }
            }
            if (errors.length !== 0) {
                console.warn(`d3cd0018    Found ${errors.length} errors when extracting values`, errors);
            }
            return successes;
        });
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

function getById<T>(collectionName: Collection, decoder: JsonDecoder.Decoder<T>): (id: string) => Promise<T | undefined> {
    return async id =>
        firestore.collection(collectionName)
            .doc(id)
            .get()
            .then(snapshot => snapshot.data())
            .then(data => {
                if (typeof data === "undefined") {
                    return undefined;
                }
                const result = decoder.decode(data);
                if (result instanceof Ok) {
                    return result.value;
                } else {
                    console.error(`5fa76ade    Error decoding ${collectionName}.${id}`, result.error, data);
                    throw new Error(`Error decoding ${collectionName}.${id}`);
                }
            });
}

/**
 * DRAFTS
 */

export const getDraftById = getById("drafts", Draft.decoder);

export async function saveDraft(draft: Draft.Draft): Promise<void> {
    firestore.collection("drafts")
        .doc(draft.id)
        .set(draft);
}

export async function getDrafts(parameters: { authorId: string, draftId?: string, levelId?: string }): Promise<Draft.Draft[]> {
    return get("drafts", parameters, Draft.decoder);
}

export async function deleteDraft(id: string): Promise<void> {
    firestore.collection("drafts")
        .doc(id)
        .delete();
}

/**
 * LEVELS
 */

export const getLevelById = getById("levels", Level.decoder);

export async function saveLevel(level: Level.Level): Promise<void> {
    firestore.collection("levels")
        .doc(level.id)
        .set(level);
}

export async function getLevels(parameters: { campaignId?: string, offset?: number, limit?: number }): Promise<Level.Level[]> {
    return get("levels", parameters, Level.decoder);
}

export async function deleteLevel(id: string): Promise<void> {
    firestore.collection("levels")
        .doc(id)
        .delete();
}

/**
 * BLUEPRINTS
 */

export const getBlueprintById = getById("blueprints", Blueprint.decoder);

export async function saveBlueprint(blueprint: Blueprint.Blueprint): Promise<void> {
    firestore.collection("blueprints")
        .doc(blueprint.id)
        .set(blueprint);
}

export async function getBlueprints(parameters: { authorId: string, offset?: number, limit?: number }): Promise<Blueprint.Blueprint[]> {
    return get("blueprints", parameters, Blueprint.decoder);
}

export async function deleteBlueprint(id: string): Promise<void> {
    firestore.collection("blueprints")
        .doc(id)
        .delete();
}

/**
 * SOLUTIONS
 */

export const getSolutionById = getById("solutions", Solution.decoder);

export async function saveSolution(solution: Solution.Solution): Promise<void> {
    firestore.collection("solutions")
        .doc(solution.id)
        .set(solution);
}

export async function getSolutions(parameters: { levelId?: string, authorId?: string, campaignId?: string }): Promise<Solution.Solution[]> {
    return get("solutions", parameters, Solution.decoder);
}

export async function deleteSolution(id: string): Promise<void> {
    firestore.collection("solutions")
        .doc(id)
        .delete();
}
