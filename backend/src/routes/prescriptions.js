const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../db/firestore');
const { jwtMiddleware, ownershipMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// ── GET /api/users/:userId/prescriptions ─────────────────────────────────────
// Supports pagination: ?page=1&limit=20
router.get('/users/:userId/prescriptions', jwtMiddleware, ownershipMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { userId } = req.params;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 20));
    const offset = (page - 1) * limit;

    const snapshot = await db.collection('prescriptions')
      .where('userId', '==', userId)
      .get();

    const allPrescriptions = [];
    snapshot.forEach(doc => {
      allPrescriptions.push({ id: doc.id, ...doc.data() });
    });

    allPrescriptions.sort((a, b) =>
      new Date(b.uploadedAt) - new Date(a.uploadedAt)
    );

    const total = allPrescriptions.length;
    const prescriptions = allPrescriptions.slice(offset, offset + limit);

    res.json({
      prescriptions,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
        hasNext: offset + limit < total,
        hasPrev: page > 1,
      },
    });
  } catch (err) {
    logger.error(`Get prescriptions error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch prescriptions' });
  }
});

// ── POST /api/users/:userId/prescriptions ────────────────────────────────────
router.post('/users/:userId/prescriptions', jwtMiddleware, ownershipMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { userId } = req.params;
    const prescription = req.body;

    const id = prescription.id || uuidv4();
    const data = {
      ...prescription,
      id,
      userId,
      uploadedAt: prescription.uploadedAt || new Date().toISOString(),
      createdAt: new Date().toISOString(),
    };

    await db.collection('prescriptions').doc(id).set(data);

    logger.info(`✅ Prescription saved: ${id} for user ${userId}`);
    res.status(201).json({ prescription: data });
  } catch (err) {
    logger.error(`Save prescription error: ${err.message}`);
    res.status(500).json({ error: 'Failed to save prescription' });
  }
});

// ── GET /api/users/:userId/prescriptions/:prescriptionId ─────────────────────
router.get('/users/:userId/prescriptions/:prescriptionId', jwtMiddleware, ownershipMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { prescriptionId } = req.params;

    const doc = await db.collection('prescriptions').doc(prescriptionId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Prescription not found' });
    }

    res.json({ prescription: { id: doc.id, ...doc.data() } });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch prescription' });
  }
});

// ── POST /api/users/:userId/prescriptions/:prescriptionId/delete ──────────────
router.post('/users/:userId/prescriptions/:prescriptionId/delete', jwtMiddleware, ownershipMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { prescriptionId } = req.params;

    await db.collection('prescriptions').doc(prescriptionId).delete();

    logger.info(`🗑️  Prescription deleted: ${prescriptionId}`);
    res.json({ message: 'Prescription deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete prescription' });
  }
});

module.exports = router;
