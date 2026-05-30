const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');
const { getDb } = require('../db/firestore');
const { jwtMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_in_production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

function generateTokens(uid, email) {
  const token = jwt.sign({ uid, email }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
  const refreshToken = jwt.sign({ uid, email, type: 'refresh' }, JWT_SECRET, {
    expiresIn: JWT_REFRESH_EXPIRES_IN,
  });
  return { token, refreshToken };
}

// ── POST /api/auth/register ───────────────────────────────────────────────────
router.post('/register', [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: errors.array()[0].msg });
  }

  const { name, email, password } = req.body;

  try {
    const db = getDb();

    // Check if user already exists
    const existing = await db.collection('users').where('email', '==', email).get();
    if (!existing.empty) {
      return res.status(409).json({ error: 'An account already exists with this email' });
    }

    const uid = uuidv4();
    const passwordHash = await bcrypt.hash(password, 12);
    const now = new Date().toISOString();

    const userData = {
      uid,
      name,
      email,
      passwordHash,
      createdAt: now,
      updatedAt: now,
    };

    await db.collection('users').doc(uid).set(userData);

    const { token, refreshToken } = generateTokens(uid, email);

    logger.info(`✅ User registered: ${email} (${uid})`);

    res.status(201).json({
      token,
      refreshToken,
      user: { uid, name, email, createdAt: now },
    });
  } catch (err) {
    logger.error(`Registration error: ${err.message}`);
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

// ── POST /api/auth/login ──────────────────────────────────────────────────────
router.post('/login', [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').notEmpty().withMessage('Password is required'),
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: errors.array()[0].msg });
  }

  const { email, password } = req.body;

  try {
    const db = getDb();
    const snapshot = await db.collection('users').where('email', '==', email).get();

    if (snapshot.empty) {
      return res.status(401).json({ error: 'No account found with this email' });
    }

    const userDoc = snapshot.docs[0];
    const userData = userDoc.data();

    const passwordMatch = await bcrypt.compare(password, userData.passwordHash);
    if (!passwordMatch) {
      return res.status(401).json({ error: 'Incorrect password. Please try again.' });
    }

    const { token, refreshToken } = generateTokens(userData.uid, userData.email);

    // Update last login
    await db.collection('users').doc(userData.uid).update({
      lastLoginAt: new Date().toISOString(),
    });

    logger.info(`✅ User logged in: ${email}`);

    res.json({
      token,
      refreshToken,
      user: {
        uid: userData.uid,
        name: userData.name,
        email: userData.email,
        createdAt: userData.createdAt,
      },
    });
  } catch (err) {
    logger.error(`Login error: ${err.message}`);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// ── POST /api/auth/refresh ────────────────────────────────────────────────────
router.post('/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return res.status(400).json({ error: 'Refresh token required' });
  }

  try {
    const decoded = jwt.verify(refreshToken, JWT_SECRET);
    if (decoded.type !== 'refresh') {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }

    const { token, refreshToken: newRefreshToken } = generateTokens(decoded.uid, decoded.email);
    res.json({ token, refreshToken: newRefreshToken });
  } catch (err) {
    res.status(401).json({ error: 'Invalid or expired refresh token' });
  }
});

// ── POST /api/auth/reset-password ─────────────────────────────────────────────
router.post('/reset-password', [
  body('email').isEmail().normalizeEmail(),
  body('newPassword').isLength({ min: 6 }),
], jwtMiddleware, async (req, res) => {
  const { email, newPassword } = req.body;

  try {
    const db = getDb();
    const snapshot = await db.collection('users').where('email', '==', email).get();

    if (snapshot.empty) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userDoc = snapshot.docs[0];
    const passwordHash = await bcrypt.hash(newPassword, 12);

    await db.collection('users').doc(userDoc.id).update({
      passwordHash,
      updatedAt: new Date().toISOString(),
    });

    res.json({ message: 'Password reset successfully' });
  } catch (err) {
    logger.error(`Password reset error: ${err.message}`);
    res.status(500).json({ error: 'Password reset failed' });
  }
});

// ── GET /api/auth/me ──────────────────────────────────────────────────────────
router.get('/me', jwtMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const userDoc = await db.collection('users').doc(req.user.uid).get();

    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const data = userDoc.data();
    res.json({
      user: {
        uid: data.uid,
        name: data.name,
        email: data.email,
        createdAt: data.createdAt,
        lastLoginAt: data.lastLoginAt,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

module.exports = router;
