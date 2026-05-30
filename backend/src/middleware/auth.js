const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

/**
 * Validates the X-Api-Key header sent by the Flutter app.
 * Skip in development if API_KEY is not set.
 */
const apiKeyMiddleware = (req, res, next) => {
  const apiKey = process.env.API_KEY;
  if (!apiKey || process.env.NODE_ENV === 'development') {
    return next(); // Skip in dev
  }
  const provided = req.headers['x-api-key'];
  if (!provided || provided !== apiKey) {
    return res.status(401).json({ error: 'Invalid or missing API key' });
  }
  next();
};

/**
 * Validates the Bearer JWT token in the Authorization header.
 */
const jwtMiddleware = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'dev_secret');
    req.user = decoded;
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired', code: 'TOKEN_EXPIRED' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
};

/**
 * Ensures the authenticated user can only access their own resources.
 */
const ownershipMiddleware = (req, res, next) => {
  const { userId } = req.params;
  if (userId && req.user && req.user.uid !== userId) {
    return res.status(403).json({ error: 'Access denied' });
  }
  next();
};

module.exports = { apiKeyMiddleware, jwtMiddleware, ownershipMiddleware };
