const express = require('express');
const { getDb, getAdmin } = require('../db/firestore');
const { jwtMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

/**
 * Send FCM push notification via Firebase Admin SDK.
 * Falls back gracefully if FCM is not configured.
 */
async function sendFcmNotification({ token, title, body, data = {} }) {
  try {
    const admin = getAdmin();
    if (!admin || !admin.messaging) {
      logger.warn('FCM not available — skipping push notification');
      return false;
    }

    const message = {
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: {
          channelId: 'medisure_reminders',
          sound: 'default',
          priority: 'high',
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    logger.info(`✅ FCM sent: ${response}`);
    return true;
  } catch (err) {
    logger.error(`FCM send error: ${err.message}`);
    return false;
  }
}

// ── POST /api/users/:userId/fcm-token ─────────────────────────────────────────
// Flutter app registers its FCM token here after login.
router.post('/users/:userId/fcm-token', jwtMiddleware, async (req, res) => {
  const { userId } = req.params;
  const { fcmToken, platform } = req.body;

  if (!fcmToken) {
    return res.status(400).json({ error: 'fcmToken is required' });
  }

  try {
    const db = getDb();
    await db.collection('users').doc(userId).update({
      fcmToken,
      fcmPlatform: platform || 'android',
      fcmUpdatedAt: new Date().toISOString(),
    });

    logger.info(`✅ FCM token saved for user ${userId}`);
    res.json({ message: 'FCM token registered successfully' });
  } catch (err) {
    logger.error(`FCM token save error: ${err.message}`);
    res.status(500).json({ error: 'Failed to save FCM token' });
  }
});

// ── POST /api/notifications/send ──────────────────────────────────────────────
// Send a push notification to a specific user.
router.post('/notifications/send', jwtMiddleware, async (req, res) => {
  const { userId, title, body, data } = req.body;

  if (!userId || !title || !body) {
    return res.status(400).json({ error: 'userId, title, and body are required' });
  }

  try {
    const db = getDb();
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      return res.status(400).json({ error: 'User has no FCM token registered' });
    }

    const sent = await sendFcmNotification({ token: fcmToken, title, body, data });

    // Save notification to history
    await db.collection('notifications').add({
      userId,
      title,
      body,
      data: data || {},
      sent,
      createdAt: new Date().toISOString(),
      read: false,
    });

    res.json({ success: sent, message: sent ? 'Notification sent' : 'Notification queued (FCM unavailable)' });
  } catch (err) {
    logger.error(`Send notification error: ${err.message}`);
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

// ── POST /api/notifications/send-reminder ─────────────────────────────────────
// Send medicine reminder notification to a user.
router.post('/notifications/send-reminder', jwtMiddleware, async (req, res) => {
  const { userId, medicineName, dosage, scheduledTime } = req.body;

  if (!userId || !medicineName) {
    return res.status(400).json({ error: 'userId and medicineName are required' });
  }

  try {
    const db = getDb();
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const fcmToken = userDoc.data().fcmToken;

    const title = '💊 Medicine Reminder';
    const body = dosage
      ? `Time to take ${medicineName} — ${dosage}`
      : `Time to take ${medicineName}`;

    const sent = fcmToken
      ? await sendFcmNotification({
          token: fcmToken,
          title,
          body,
          data: { type: 'reminder', medicineName, dosage: dosage || '', scheduledTime: scheduledTime || '' },
        })
      : false;

    res.json({ success: sent });
  } catch (err) {
    logger.error(`Send reminder error: ${err.message}`);
    res.status(500).json({ error: 'Failed to send reminder' });
  }
});

// ── GET /api/users/:userId/notifications ──────────────────────────────────────
// Get notification history for a user.
router.get('/users/:userId/notifications', jwtMiddleware, async (req, res) => {
  const { userId } = req.params;

  try {
    const db = getDb();
    const snapshot = await db.collection('notifications')
      .where('userId', '==', userId)
      .get();

    const notifications = [];
    snapshot.forEach(doc => notifications.push({ id: doc.id, ...doc.data() }));
    notifications.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({ notifications: notifications.slice(0, 50) });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// ── PATCH /api/notifications/:notificationId/read ─────────────────────────────
router.patch('/notifications/:notificationId/read', jwtMiddleware, async (req, res) => {
  try {
    const db = getDb();
    await db.collection('notifications').doc(req.params.notificationId).update({
      read: true,
      readAt: new Date().toISOString(),
    });
    res.json({ message: 'Marked as read' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to mark as read' });
  }
});

module.exports = router;
