const request = require('supertest');
const app = require('../index');

describe('Health check', () => {
  it('GET /health returns status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('Auth routes', () => {
  it('POST /api/auth/register rejects missing fields', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ email: 'test@test.com' }); // missing name and password
    expect(res.statusCode).toBe(400);
  });

  it('POST /api/auth/login rejects invalid email', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'not-an-email', password: '123456' });
    expect(res.statusCode).toBe(400);
  });

  it('POST /api/auth/login returns 401 for unknown user', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'nobody@example.com', password: 'password123' });
    expect(res.statusCode).toBe(401);
  });
});

describe('Orders route validation', () => {
  it('POST /api/orders rejects request without auth token', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('X-Api-Key', process.env.API_KEY || 'ci_test_api_key')
      .send({ userId: 'test', pharmacyName: 'Test Pharmacy' });
    expect(res.statusCode).toBe(401);
  });
});

describe('OCR route', () => {
  it('POST /api/ocr/extract-base64 rejects missing imageBase64', async () => {
    const res = await request(app)
      .post('/api/ocr/extract-base64')
      .set('X-Api-Key', process.env.API_KEY || 'ci_test_api_key')
      .send({});
    // 401 (no auth) or 400 (missing field) — both are correct
    expect([400, 401]).toContain(res.statusCode);
  });
});
