const admin = require('firebase-admin');
const path = require('path');
const logger = require('../utils/logger');

let db = null;
let initialized = false;

/**
 * Initialize Firebase Admin SDK.
 * Falls back to in-memory store if Firebase is not configured (for local dev).
 */
function initFirebase() {
  if (initialized) return;

  const serviceAccountPath = process.env.NODE_ENV === 'test' ? null : process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (serviceAccountPath) {
    try {
      const serviceAccount = require(path.resolve(serviceAccountPath));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: process.env.FIREBASE_PROJECT_ID,
      });
      db = admin.firestore();
      logger.info('✅ Firebase Admin SDK initialized');
    } catch (err) {
      logger.warn(`⚠️  Firebase init failed: ${err.message}. Using in-memory store.`);
      db = createInMemoryStore();
    }
  } else {
    logger.warn('⚠️  FIREBASE_SERVICE_ACCOUNT_PATH not set. Using in-memory store.');
    db = createInMemoryStore();
  }

  initialized = true;
}

/**
 * Simple in-memory store that mimics Firestore API for local development.
 * Data is lost on server restart — use Firebase for production.
 */
function createInMemoryStore() {
  const store = {};

  const collection = (name) => ({
    doc: (id) => ({
      get: async () => {
        const data = store[name]?.[id];
        return { exists: !!data, data: () => data, id };
      },
      set: async (data) => {
        store[name] = store[name] || {};
        store[name][id] = { ...data, id };
      },
      update: async (data) => {
        store[name] = store[name] || {};
        store[name][id] = { ...(store[name][id] || {}), ...data };
      },
      delete: async () => {
        if (store[name]) delete store[name][id];
      },
    }),
    where: (field, op, value) => ({
      get: async () => {
        const docs = Object.values(store[name] || {}).filter(doc => {
          if (op === '==') return doc[field] === value;
          if (op === '!=') return doc[field] !== value;
          return true;
        });
        return {
          empty: docs.length === 0,
          docs: docs.map(d => ({ id: d.id, data: () => d, exists: true })),
          forEach: (fn) => docs.forEach(d => fn({ id: d.id, data: () => d })),
        };
      },
      orderBy: () => ({
        get: async () => {
          const docs = Object.values(store[name] || {}).filter(doc => {
            if (op === '==') return doc[field] === value;
            return true;
          });
          return {
            empty: docs.length === 0,
            docs: docs.map(d => ({ id: d.id, data: () => d, exists: true })),
          };
        },
      }),
    }),
    add: async (data) => {
      const id = `${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      store[name] = store[name] || {};
      store[name][id] = { ...data, id };
      return { id };
    },
    get: async () => {
      const docs = Object.values(store[name] || {});
      return {
        empty: docs.length === 0,
        docs: docs.map(d => ({ id: d.id, data: () => d, exists: true })),
      };
    },
  });

  return { collection };
}

function getDb() {
  if (!initialized) initFirebase();
  return db;
}

function getAdmin() {
  if (!initialized) initFirebase();
  return admin;
}

module.exports = { initFirebase, getDb, getAdmin };
