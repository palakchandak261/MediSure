const express = require('express');
const multer = require('multer');
const https = require('https');
const http = require('http');
const { jwtMiddleware } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Store image in memory (no disk writes)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  },
});

/**
 * Call Google Vision API to extract text from an image buffer.
 */
async function callGoogleVision(imageBuffer) {
  const apiKey = process.env.GOOGLE_VISION_API_KEY;
  if (!apiKey || apiKey === 'your_google_vision_api_key') {
    throw new Error('GOOGLE_VISION_API_KEY not configured');
  }

  const base64Image = imageBuffer.toString('base64');
  const requestBody = JSON.stringify({
    requests: [{
      image: { content: base64Image },
      features: [
        { type: 'TEXT_DETECTION', maxResults: 1 },
        { type: 'DOCUMENT_TEXT_DETECTION', maxResults: 1 },
      ],
    }],
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'vision.googleapis.com',
      path: `/v1/images:annotate?key=${apiKey}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestBody),
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.error) {
            reject(new Error(parsed.error.message));
            return;
          }
          const response = parsed.responses?.[0];
          const fullText = response?.fullTextAnnotation?.text ||
                           response?.textAnnotations?.[0]?.description || '';
          resolve(fullText);
        } catch (e) {
          reject(new Error('Failed to parse Vision API response'));
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(30000, () => {
      req.destroy();
      reject(new Error('Vision API request timed out'));
    });
    req.write(requestBody);
    req.end();
  });
}

// ── POST /api/ocr/extract ─────────────────────────────────────────────────────
// Accepts a multipart image upload, returns extracted text.
router.post('/ocr/extract', jwtMiddleware, upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'Image file is required' });
  }

  try {
    logger.info(`🔍 OCR request: ${req.file.originalname} (${req.file.size} bytes)`);

    const extractedText = await callGoogleVision(req.file.buffer);

    if (!extractedText || extractedText.trim().length === 0) {
      return res.json({
        extractedText: '',
        success: false,
        error: 'No text detected in image. Please ensure good lighting and a clear prescription.',
      });
    }

    logger.info(`✅ OCR extracted ${extractedText.length} characters`);

    res.json({
      extractedText,
      success: true,
      charCount: extractedText.length,
    });
  } catch (err) {
    logger.error(`OCR error: ${err.message}`);

    if (err.message.includes('not configured')) {
      return res.status(503).json({
        error: 'OCR service not configured. Please set GOOGLE_VISION_API_KEY.',
        extractedText: '',
        success: false,
      });
    }

    res.status(500).json({
      error: 'OCR processing failed. Please try again.',
      extractedText: '',
      success: false,
    });
  }
});

// ── POST /api/ocr/extract-base64 ──────────────────────────────────────────────
// Accepts base64 image in JSON body (for web clients that can't use multipart)
router.post('/ocr/extract-base64', jwtMiddleware, async (req, res) => {
  const { imageBase64, mimeType = 'image/jpeg' } = req.body;

  if (!imageBase64) {
    return res.status(400).json({ error: 'imageBase64 is required' });
  }

  try {
    const imageBuffer = Buffer.from(imageBase64, 'base64');
    logger.info(`🔍 OCR base64 request: ${imageBuffer.length} bytes`);

    const extractedText = await callGoogleVision(imageBuffer);

    if (!extractedText || extractedText.trim().length === 0) {
      return res.json({
        extractedText: '',
        success: false,
        error: 'No text detected. Please use a clearer image.',
      });
    }

    res.json({ extractedText, success: true });
  } catch (err) {
    logger.error(`OCR base64 error: ${err.message}`);
    res.status(500).json({ error: err.message, extractedText: '', success: false });
  }
});

module.exports = router;
