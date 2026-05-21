const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose'); // <-- Neu hinzugefügt
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// --- MONGODB VERBINDUNG ---
// Holt sich die URI aus der .env Datei
const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/shareway';

mongoose.connect(mongoURI)
  .then(() => console.log('🟢 [MongoDB] Erfolgreich verbunden!'))
  .catch(err => console.error('🔴 [MongoDB] Verbindungsfehler:', err));
// --------------------------

// Erste Test-Route
app.get('/', (req, res) => {
  res.send('SHAREWAY Backend läuft einwandfrei! 🚀');
});

// Server starten
app.listen(PORT, () => {
  console.log(`[Server] Läuft auf Port ${PORT}`);
});