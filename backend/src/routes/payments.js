const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { jwtMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Lazily initialize Razorpay so the server starts even without keys
let razorpay = null;
function getRazorpay() {
  if (!razorpay) {
    const Razorpay = require('razorpay');
    const keyId = process.env.RAZORPAY_KEY_ID;
    const keySecret = process.env.RAZORPAY_KEY_SECRET;

    if (!keyId || !keySecret || keyId.startsWith('rzp_test_your')) {
      return null; // Not configured
    }

    razorpay = new Razorpay({ key_id: keyId, key_secret: keySecret });
  }
  return razorpay;
}

// ── POST /api/payments/razorpay-order ─────────────────────────────────────────
// Creates a Razorpay order. Flutter app uses this to initiate payment.
router.post('/payments/razorpay-order', jwtMiddleware, async (req, res) => {
  const { amount, currency = 'INR', orderId, pharmacyName } = req.body;

  if (!amount || amount <= 0) {
    return res.status(400).json({ error: 'Valid amount is required' });
  }

  const rp = getRazorpay();

  if (!rp) {
    // Fallback: return UPI session for direct UPI payment
    logger.warn('Razorpay not configured — returning UPI fallback');
    return res.json({
      paymentSession: {
        paymentReference: orderId || uuidv4(),
        upiId: process.env.UPI_ID || 'medisure@upi',
        payeeName: process.env.UPI_PAYEE_NAME || 'MediSure',
        amount: parseFloat(amount),
        note: `MediSure Order #${orderId}`,
        requiresVerification: false,
        type: 'upi_fallback',
      },
    });
  }

  try {
    const options = {
      amount: Math.round(parseFloat(amount) * 100), // Razorpay uses paise
      currency,
      receipt: `receipt_${orderId || uuidv4()}`,
      notes: {
        pharmacyName: pharmacyName || 'MediSure',
        orderId: orderId || '',
      },
    };

    const order = await rp.orders.create(options);

    logger.info(`✅ Razorpay order created: ${order.id}`);

    res.json({
      paymentSession: {
        paymentReference: order.id,
        razorpayOrderId: order.id,
        razorpayKeyId: process.env.RAZORPAY_KEY_ID,
        amount: parseFloat(amount),
        currency,
        note: `MediSure Order #${orderId}`,
        requiresVerification: true,
        type: 'razorpay',
      },
    });
  } catch (err) {
    logger.error(`Razorpay order creation failed: ${err.message}`);
    res.status(500).json({ error: 'Payment initialization failed' });
  }
});

// ── POST /api/payments/upi-session ────────────────────────────────────────────
// Legacy UPI session endpoint (used by Flutter BackendService)
// Also handles Razorpay order creation when type='razorpay'
router.post('/payments/upi-session', jwtMiddleware, async (req, res) => {
  const { orderId, amount, pharmacyName, type } = req.body;

  // If Razorpay is configured and type is razorpay, create a Razorpay order
  if (type === 'razorpay') {
    const rp = getRazorpay();
    if (rp) {
      try {
        const options = {
          amount: Math.round(parseFloat(amount) * 100),
          currency: 'INR',
          receipt: `receipt_${orderId || uuidv4()}`,
          notes: { pharmacyName: pharmacyName || 'MediSure', orderId: orderId || '' },
        };
        const order = await rp.orders.create(options);
        logger.info(`✅ Razorpay order created via upi-session: ${order.id}`);
        return res.json({
          paymentSession: {
            paymentReference: order.id,
            razorpayOrderId: order.id,
            razorpayKeyId: process.env.RAZORPAY_KEY_ID,
            upiId: process.env.UPI_ID || 'medisure@upi',
            payeeName: pharmacyName || process.env.UPI_PAYEE_NAME || 'MediSure',
            amount: parseFloat(amount || 0),
            note: `MediSure Order #${orderId}`,
            requiresVerification: true,
            type: 'razorpay',
          },
        });
      } catch (err) {
        logger.error(`Razorpay order creation failed: ${err.message}`);
        // Fall through to UPI fallback
      }
    }
  }

  // Default: UPI session
  res.json({
    paymentSession: {
      paymentReference: orderId || uuidv4(),
      upiId: process.env.UPI_ID || 'medisure@upi',
      payeeName: pharmacyName || process.env.UPI_PAYEE_NAME || 'MediSure',
      amount: parseFloat(amount || 0),
      note: `MediSure Order #${orderId}`,
      requiresVerification: false,
      type: 'upi_fallback',
    },
  });
});

// ── POST /api/payments/verify ─────────────────────────────────────────────────
// Verifies a Razorpay payment signature.
router.post('/payments/verify', jwtMiddleware, async (req, res) => {
  const { paymentReference, razorpayPaymentId, razorpaySignature } = req.body;

  if (!paymentReference) {
    return res.status(400).json({ error: 'paymentReference is required' });
  }

  const rp = getRazorpay();

  if (!rp || !razorpayPaymentId || !razorpaySignature) {
    // No Razorpay configured or UPI payment — auto-verify
    logger.info(`Payment auto-verified (no Razorpay): ${paymentReference}`);
    return res.json({ status: 'success', paymentReference });
  }

  try {
    const crypto = require('crypto');
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${paymentReference}|${razorpayPaymentId}`)
      .digest('hex');

    if (expectedSignature !== razorpaySignature) {
      logger.warn(`Payment signature mismatch: ${paymentReference}`);
      return res.status(400).json({ status: 'failed', error: 'Invalid payment signature' });
    }

    logger.info(`✅ Payment verified: ${razorpayPaymentId}`);
    res.json({ status: 'success', paymentReference, razorpayPaymentId });
  } catch (err) {
    logger.error(`Payment verification error: ${err.message}`);
    res.status(500).json({ error: 'Payment verification failed' });
  }
});

module.exports = router;
