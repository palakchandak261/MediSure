const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { getDb } = require('../db/firestore');
const { jwtMiddleware, ownershipMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// ── GET /api/users/:userId/orders ─────────────────────────────────────────────
// Supports pagination: ?page=1&limit=20
router.get('/users/:userId/orders', jwtMiddleware, ownershipMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { userId } = req.params;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 20));
    const offset = (page - 1) * limit;

    const snapshot = await db.collection('orders').where('userId', '==', userId).get();

    const allOrders = [];
    snapshot.forEach(doc => allOrders.push({ id: doc.id, ...doc.data() }));
    allOrders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    const total = allOrders.length;
    const orders = allOrders.slice(offset, offset + limit);

    res.json({
      orders,
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
    logger.error(`Get orders error: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// ── POST /api/orders ──────────────────────────────────────────────────────────
router.post('/orders', jwtMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const orderData = req.body;

    // ── Input validation ────────────────────────────────────────────────────
    if (!orderData.userId || typeof orderData.userId !== 'string') {
      return res.status(400).json({ error: 'userId is required' });
    }
    if (!orderData.pharmacyName || typeof orderData.pharmacyName !== 'string') {
      return res.status(400).json({ error: 'pharmacyName is required' });
    }
    if (!Array.isArray(orderData.items) || orderData.items.length === 0) {
      return res.status(400).json({ error: 'items must be a non-empty array' });
    }
    if (!orderData.deliveryAddress || typeof orderData.deliveryAddress !== 'string') {
      return res.status(400).json({ error: 'deliveryAddress is required' });
    }
    // Sanitize: strip any attempt to inject extra fields
    const allowedFields = [
      'userId', 'pharmacyName', 'pharmacyAddress', 'items',
      'deliveryAddress', 'paymentMethod', 'contactEmail',
      'contactPhone', 'contactType', 'totalAmount',
    ];
    const sanitized = {};
    for (const field of allowedFields) {
      if (orderData[field] !== undefined) sanitized[field] = orderData[field];
    }

    const id = uuidv4();
    const now = new Date().toISOString();

    const order = {
      ...sanitized,
      id,
      status: 'confirmed',
      createdAt: now,
      updatedAt: now,
      statusHistory: [
        { status: 'confirmed', timestamp: now, note: 'Order placed successfully' },
      ],
    };

    await db.collection('orders').doc(id).set(order);

    logger.info(`✅ Order placed: ${id}`);
    res.status(201).json({ order });
  } catch (err) {
    logger.error(`Place order error: ${err.message}`);
    res.status(500).json({ error: 'Failed to place order' });
  }
});

// ── GET /api/orders/:orderId ──────────────────────────────────────────────────
router.get('/orders/:orderId', jwtMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const doc = await db.collection('orders').doc(req.params.orderId).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json({ order: { id: doc.id, ...doc.data() } });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch order' });
  }
});

// ── PATCH /api/orders/:orderId/status ─────────────────────────────────────────
router.patch('/orders/:orderId/status', jwtMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { status, note } = req.body;
    const now = new Date().toISOString();

    const doc = await db.collection('orders').doc(req.params.orderId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const existing = doc.data();
    const statusHistory = existing.statusHistory || [];
    statusHistory.push({ status, timestamp: now, note: note || '' });

    await db.collection('orders').doc(req.params.orderId).update({
      status,
      updatedAt: now,
      statusHistory,
    });

    res.json({ message: 'Order status updated', status });
  } catch (err) {
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

module.exports = router;
