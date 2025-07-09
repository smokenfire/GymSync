const request = require('supertest');
const express = require('express');
const cors = require('cors');

// Mock environment variables
process.env.API_KEY = 'test-key';

// Import the routes from the main app
// We need to create a separate app instance for testing
const app = express();
app.use(cors());
app.use(express.json());

// In-memory store for testing
const statusMap = new Map();

// Root endpoint
app.get("/", (req, res) => {
  res.send("✅ GymSync Backend is running!");
});

// POST /api/v1/status
app.post("/api/v1/status", (req, res) => {
  const auth = req.headers.authorization || "";
  const token = auth.split(" ")[1];

  if (token !== process.env.API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { discord_id, status } = req.body;

  if (
    !discord_id ||
    !status ||
    typeof status.activity !== "string"
  ) {
    return res.status(400).json({ error: "Invalid payload" });
  }

  statusMap.set(discord_id, {
    activity: status.activity,
    startTimestamp: Date.now(),
    paused: false,
    pausedElapsed: 0,
  });

  res.json({ ok: true });
});

// POST /api/v1/status/pause
app.post("/api/v1/status/pause", (req, res) => {
  const auth = req.headers.authorization || "";
  const token = auth.split(" ")[1];

  if (token !== process.env.API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { discord_id } = req.body;

  if (!discord_id) {
    return res.status(400).json({ error: "discord_id is required" });
  }
  const data = statusMap.get(discord_id);
  if (!data) {
    return res.status(404).json({ error: "Status not found" });
  }
  if (data.paused) {
    return res.status(400).json({ error: "Already paused" });
  }

  const now = Date.now();
  const elapsed = Math.floor((now - data.startTimestamp) / 1000);
  data.pausedElapsed += elapsed;
  data.paused = true;
  data.startTimestamp = null;
  statusMap.set(discord_id, data);

  res.json({ ok: true });
});

// POST /api/v1/status/resume
app.post("/api/v1/status/resume", (req, res) => {
  const auth = req.headers.authorization || "";
  const token = auth.split(" ")[1];

  if (token !== process.env.API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { discord_id } = req.body;

  if (!discord_id) {
    return res.status(400).json({ error: "discord_id is required" });
  }
  const data = statusMap.get(discord_id);
  if (!data || !data.paused) {
    return res.status(404).json({ error: "Nothing to resume" });
  }

  data.paused = false;
  data.startTimestamp = Date.now();
  statusMap.set(discord_id, data);

  res.json({ ok: true });
});

// POST /api/v1/status/stop
app.post("/api/v1/status/stop", (req, res) => {
  const auth = req.headers.authorization || "";
  const token = auth.split(" ")[1];

  if (token !== process.env.API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { discord_id } = req.body;

  if (!discord_id) {
    return res.status(400).json({ error: "discord_id is required" });
  }
  statusMap.delete(discord_id);
  res.json({ ok: true });
});

// GET /api/v1/status/:discord_id
app.get("/api/v1/status/:discord_id", (req, res) => {
  const discord_id = req.params.discord_id;
  const data = statusMap.get(discord_id);
  if (!data) {
    return res.status(404).json({ error: "Not found" });
  }

  if (data.paused) {
    return res.json({
      activity: data.activity,
      time: data.pausedElapsed,
      paused: true
    });
  } else {
    const now = Date.now();
    const elapsed = Math.floor((now - data.startTimestamp) / 1000) + data.pausedElapsed;
    return res.json({
      activity: data.activity,
      time: elapsed,
      paused: false
    });
  }
});

// Tests
describe('GymSync Backend API', () => {
  beforeEach(() => {
    // Clear the status map before each test
    statusMap.clear();
  });

  test('GET / should return a welcome message', async () => {
    const response = await request(app).get('/');
    expect(response.status).toBe(200);
    expect(response.text).toBe('✅ GymSync Backend is running!');
  });

  test('POST /api/v1/status should create a new status', async () => {
    const response = await request(app)
      .post('/api/v1/status')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789',
        status: {
          activity: 'running'
        }
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ ok: true });
    
    // Verify the status was created
    const statusResponse = await request(app).get('/api/v1/status/123456789');
    expect(statusResponse.status).toBe(200);
    expect(statusResponse.body.activity).toBe('running');
    expect(statusResponse.body.paused).toBe(false);
  });

  test('POST /api/v1/status should return 401 with invalid API key', async () => {
    const response = await request(app)
      .post('/api/v1/status')
      .set('Authorization', 'Bearer invalid-key')
      .send({
        discord_id: '123456789',
        status: {
          activity: 'running'
        }
      });
    
    expect(response.status).toBe(401);
    expect(response.body).toEqual({ error: 'Unauthorized' });
  });

  test('POST /api/v1/status should return 400 with invalid payload', async () => {
    const response = await request(app)
      .post('/api/v1/status')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789',
        // Missing status
      });
    
    expect(response.status).toBe(400);
    expect(response.body).toEqual({ error: 'Invalid payload' });
  });

  test('POST /api/v1/status/pause should pause an activity', async () => {
    // First create a status
    await request(app)
      .post('/api/v1/status')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789',
        status: {
          activity: 'running'
        }
      });
    
    // Then pause it
    const response = await request(app)
      .post('/api/v1/status/pause')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789'
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ ok: true });
    
    // Verify the status was paused
    const statusResponse = await request(app).get('/api/v1/status/123456789');
    expect(statusResponse.status).toBe(200);
    expect(statusResponse.body.activity).toBe('running');
    expect(statusResponse.body.paused).toBe(true);
  });

  test('POST /api/v1/status/resume should resume a paused activity', async () => {
    // First create a status
    await request(app)
      .post('/api/v1/status')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789',
        status: {
          activity: 'running'
        }
      });
    
    // Then pause it
    await request(app)
      .post('/api/v1/status/pause')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789'
      });
    
    // Then resume it
    const response = await request(app)
      .post('/api/v1/status/resume')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789'
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ ok: true });
    
    // Verify the status was resumed
    const statusResponse = await request(app).get('/api/v1/status/123456789');
    expect(statusResponse.status).toBe(200);
    expect(statusResponse.body.activity).toBe('running');
    expect(statusResponse.body.paused).toBe(false);
  });

  test('POST /api/v1/status/stop should remove a status', async () => {
    // First create a status
    await request(app)
      .post('/api/v1/status')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789',
        status: {
          activity: 'running'
        }
      });
    
    // Then stop it
    const response = await request(app)
      .post('/api/v1/status/stop')
      .set('Authorization', 'Bearer test-key')
      .send({
        discord_id: '123456789'
      });
    
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ ok: true });
    
    // Verify the status was removed
    const statusResponse = await request(app).get('/api/v1/status/123456789');
    expect(statusResponse.status).toBe(404);
    expect(statusResponse.body).toEqual({ error: 'Not found' });
  });

  test('GET /api/v1/status/:discord_id should return 404 for non-existent status', async () => {
    const response = await request(app).get('/api/v1/status/non-existent');
    expect(response.status).toBe(404);
    expect(response.body).toEqual({ error: 'Not found' });
  });
});