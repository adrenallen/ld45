const express = require('express');
const cors = require('cors');
const Database = require('better-sqlite3');
const path = require('path');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

// --- Database Setup ---
const db = new Database(path.join(__dirname, 'planet_jumpers.db'));
db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS deaths (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    week_id TEXT NOT NULL,
    player_name TEXT NOT NULL,
    phase INTEGER NOT NULL,
    position_x REAL NOT NULL,
    position_y REAL NOT NULL,
    distance REAL NOT NULL DEFAULT 0,
    fuel REAL NOT NULL DEFAULT 0,
    oxygen REAL NOT NULL DEFAULT 0,
    ship_health INTEGER NOT NULL DEFAULT 0,
    planets_landed_on INTEGER NOT NULL DEFAULT 0,
    death_cause TEXT,
    planet_biome TEXT,
    planet_radius REAL,
    planet_gravity REAL,
    planet_toxicity REAL,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE INDEX IF NOT EXISTS idx_deaths_week_id ON deaths(week_id);
  CREATE INDEX IF NOT EXISTS idx_deaths_week_phase ON deaths(week_id, phase);
`);

// --- Weekly Seed Logic ---
function getWeekId(date = new Date()) {
  // Week starts on Monday. ISO week number + year = unique week identifier.
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  // Set to nearest Thursday (ISO week algorithm)
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const weekNum = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
  return `${d.getUTCFullYear()}-W${String(weekNum).padStart(2, '0')}`;
}

function getWeekBounds(date = new Date()) {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const day = d.getUTCDay() || 7; // Monday=1 ... Sunday=7
  const monday = new Date(d);
  monday.setUTCDate(d.getUTCDate() - day + 1);
  monday.setUTCHours(0, 0, 0, 0);
  const sunday = new Date(monday);
  sunday.setUTCDate(monday.getUTCDate() + 6);
  sunday.setUTCHours(23, 59, 59, 999);
  return { start: monday.toISOString(), end: sunday.toISOString() };
}

function generateSeed(weekId) {
  // Deterministic seed from weekId using a hash
  const hash = crypto.createHash('sha256').update(`planet-jumpers-${weekId}`).digest();
  // Use first 4 bytes as a 32-bit integer seed
  return hash.readUInt32BE(0);
}

// --- Routes ---

// Get current weekly seed
app.get('/api/weekly-seed', (req, res) => {
  const weekId = getWeekId();
  const bounds = getWeekBounds();
  const seed = generateSeed(weekId);

  res.json({
    weekId,
    seed,
    weekStart: bounds.start,
    weekEnd: bounds.end
  });
});

// Submit a death marker
app.post('/api/deaths', (req, res) => {
  const {
    weekId, playerName, phase,
    positionX, positionY, distance,
    fuel, oxygen, shipHealth, planetsLandedOn,
    deathCause, planetBiome, planetRadius, planetGravity, planetToxicity
  } = req.body;

  if (!weekId || !playerName || phase == null) {
    return res.status(400).json({ error: 'weekId, playerName, and phase are required' });
  }

  if (playerName.length > 32) {
    return res.status(400).json({ error: 'playerName must be 32 characters or less' });
  }

  const stmt = db.prepare(`
    INSERT INTO deaths (
      week_id, player_name, phase, position_x, position_y, distance,
      fuel, oxygen, ship_health, planets_landed_on,
      death_cause, planet_biome, planet_radius, planet_gravity, planet_toxicity
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  const result = stmt.run(
    weekId, playerName, phase,
    positionX || 0, positionY || 0, distance || 0,
    fuel || 0, oxygen || 0, shipHealth || 0, planetsLandedOn || 0,
    deathCause || null, planetBiome || null,
    planetRadius || null, planetGravity || null, planetToxicity || null
  );

  res.json({ id: result.lastInsertRowid });
});

// Get all deaths for a given week
app.get('/api/deaths/:weekId', (req, res) => {
  const { weekId } = req.params;
  const phase = req.query.phase != null ? parseInt(req.query.phase) : null;

  let stmt;
  let rows;

  if (phase != null) {
    stmt = db.prepare('SELECT * FROM deaths WHERE week_id = ? AND phase = ? ORDER BY created_at DESC LIMIT 200');
    rows = stmt.all(weekId, phase);
  } else {
    stmt = db.prepare('SELECT * FROM deaths WHERE week_id = ? ORDER BY created_at DESC LIMIT 200');
    rows = stmt.all(weekId);
  }

  res.json(rows.map(row => ({
    id: row.id,
    playerName: row.player_name,
    phase: row.phase,
    positionX: row.position_x,
    positionY: row.position_y,
    distance: row.distance,
    fuel: row.fuel,
    oxygen: row.oxygen,
    shipHealth: row.ship_health,
    planetsLandedOn: row.planets_landed_on,
    deathCause: row.death_cause,
    planetBiome: row.planet_biome,
    planetRadius: row.planet_radius,
    planetGravity: row.planet_gravity,
    planetToxicity: row.planet_toxicity,
    createdAt: row.created_at
  })));
});

// Weekly leaderboard (top runs for the current week, sorted by distance)
app.get('/api/weekly-leaderboard/:weekId', (req, res) => {
  const { weekId } = req.params;
  const stmt = db.prepare(`
    SELECT * FROM deaths WHERE week_id = ?
    ORDER BY distance DESC LIMIT 20
  `);
  const rows = stmt.all(weekId);

  res.json(rows.map(row => ({
    id: row.id,
    playerName: row.player_name,
    distance: row.distance,
    phase: row.phase,
    deathCause: row.death_cause,
    planetBiome: row.planet_biome,
    planetsLandedOn: row.planets_landed_on,
    createdAt: row.created_at
  })));
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Planet Jumpers multiplayer server running on port ${PORT}`);
});
