// Cloud Functions for Fast Menja
// Deploy with: firebase deploy --only functions

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Create user profile on new auth user
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  
  await db.collection('users').doc(user.uid).set({
    displayName: user.displayName || 'User',
    email: user.email,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isPremium: false,
  });
});

// Send daily reminder notification
exports.sendDailyReminder = functions.pubsub
  .schedule('every day 09:00')
  .timeZone('Europe/London')
  .onRun(async (context) => {
    const db = admin.firestore();
    const messaging = admin.messaging();
    
    const usersSnapshot = await db.collection('users').get();
    
    const notifications = [];
    usersSnapshot.forEach((doc) => {
      if (doc.data().fcmToken) {
        notifications.push(
          messaging.send({
            token: doc.data().fcmToken,
            notification: {
              title: 'Daily Study Streak',
              body: 'Keep your learning streak going! Take a mock test today.',
            },
            data: {
              screen: 'mock-test',
            },
          })
        );
      }
    });
    
    await Promise.all(notifications);
    console.log('Sent daily reminders');
  });

// Validate premium status via RevenueCat webhook
exports.validatePremium = functions.firestore
  .document('users/{userId}')
  .onWrite(async (change, context) => {
    // This would connect to RevenueCat API to verify subscription
    // Simplified version shown here
    console.log('Premium status updated for user:', context.params.userId);
  });

// Aggregate quiz statistics
exports.aggregateStats = functions.firestore
  .document('users/{userId}/quizStats/{category}')
  .onWrite(async (change, context) => {
    console.log('Stats updated for:', context.params.userId, context.params.category);
  });
