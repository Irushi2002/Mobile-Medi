const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// ─────────────────────────────────────────────────────────────────────────────
// Cloud Function: markOverdueMedications
// ─────────────────────────────────────────────────────────────────────────────
// Runs every hour. Checks all users' medications. If a scheduled dose time has
// passed and the takenStatus for that time is still "pending" (or empty),
// it updates the takenStatus to "overdue".
// ─────────────────────────────────────────────────────────────────────────────
exports.markOverdueMedications = functions.pubsub
    .schedule("every 60 minutes")
    .onRun(async (context) => {
        const db = admin.firestore();
        const now = Date.now();

        // Warning: In a massive production system with millions of users,
        // you would want to structure this differently (e.g., querying only active users).
        // For a hospital system this is perfectly fine.
        const usersSnapshot = await db.collection("users").get();
        let updatedCount = 0;

        for (const userDoc of usersSnapshot.docs) {
            const medsSnapshot = await userDoc.ref.collection("medications").get();

            for (const medDoc of medsSnapshot.docs) {
                const data = medDoc.data();
                const scheduledTimes = data.scheduledTimes || [];
                const takenStatus = data.takenStatus || {};
                const updates = {};

                for (const time of scheduledTimes) {
                    const date = new Date(time);
                    // Format the key to match exactly how the Flutter app stores it:
                    // 'yyyy-MM-dd_HH:mm'
                    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}_${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;

                    // If the time has passed and status isn't recorded or is 'pending', mark as overdue
                    if (time < now && (!takenStatus[key] || takenStatus[key] === "pending")) {
                        updates[`takenStatus.${key}`] = "overdue";
                    }
                }

                if (Object.keys(updates).length > 0) {
                    await medDoc.ref.update(updates);
                    updatedCount++;
                }
            }
        }

        console.log(`Overdue check complete. Updated ${updatedCount} medications.`);
        return null;
    });

// ─────────────────────────────────────────────────────────────────────────────
// Cloud Function: onCheckInSubmitted
// ─────────────────────────────────────────────────────────────────────────────
// Triggers when a new CheckIn is created. If the healthStatus is 'critical',
// we could (in the future) send an emergency alert/email to the doctor or hospital.
// ─────────────────────────────────────────────────────────────────────────────
exports.onCheckInSubmitted = functions.firestore
    .document('users/{userId}/checkIns/{checkInId}')
    .onCreate(async (snap, context) => {
        const checkIn = snap.data();
        
        if (checkIn.healthStatus === 'critical') {
            console.warn(`CRITICAL Check-In received for User: ${context.params.userId}`);
            // Future implementation: Send email/SMS alert to hospital staff here
        }
        return null;
    });
