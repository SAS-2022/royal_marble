import * as functions from "firebase-functions";


// export const helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.createLocation = functions.firestore
    .document('users/{usersId}')
    .onCreate((snap, context) => {
        const record = snap.data();
        const location = record.location;

        console.log('[data] - ', record);

        return snap.ref.set({
            uuid: location.uuid,
            timestamp: location.timestamp,
            is_moving: location.is_moving,
            latitude: location.coords.latitude,
            longitude: location.coords.longitude,
            event: location.event,
        });
    });
