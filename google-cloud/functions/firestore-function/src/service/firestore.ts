import {Firestore} from '@google-cloud/firestore'
import * as SavedLevel from "../data/SavedLevel";
import DocumentSnapshot = FirebaseFirestore.DocumentSnapshot;
import {PostDraftRequest} from "../data/PostDraftRequest";
import {assignmentStatusType} from "aws-sdk/clients/iam";
import {accessSync} from "fs";

const PROJECT_ID = 'luminous-cubist-234816';
const firestore: Firestore = new Firestore({
    projectId: PROJECT_ID
});

export async function getUserBySubject(subject: string): Promise<DocumentSnapshot> {
    const usersCollection = firestore.collection('users');
    return usersCollection.where("subjectAuth0", "==", subject)
        .limit(1)
        .get()
        .then(snapshot =>
            snapshot.empty
                ? usersCollection.add({subjectAuth0: subject})
                    .then(ref => ref.get())
                : snapshot.docs[0]);
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

export async function getDrafts(parameters: {authorId: string}) {
    return firestore.collection("drafts")
        .where("authorId", "==", parameters.authorId)
        .get();
}

export async function addDraft(draft: PostDraftRequest) {
    return firestore.collection("drafts")
        .add(draft);
}

export async function getDraftDocument(id) {
    return firestore.collection("drafts")
        .doc(id);
}

/**
 * LEVELS
 */

export const getLevelById = getById("levels");

export async function getLevels(parameters: { offset?: number, limit?: number } = {}): Promise<FirebaseFirestore.QuerySnapshot> {
    return firestore.collection('levels')
        .offset(parameters.offset)
        .limit(parameters.limit)
        .get()
}


export async function addLevel(level: SavedLevel.SavedLevel): Promise<FirebaseFirestore.DocumentReference> {
    return firestore.collection('levels')
        .add(level)
}

/**
 * Solutions
 */

export const getSolutionById = getById("solutions");
