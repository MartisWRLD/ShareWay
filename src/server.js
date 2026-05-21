const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
require('dotenv').config();

// 1. Das Ride-Modell importieren
const Ride = require('./models/Ride');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// --- MONGODB VERBINDUNG ---
const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/shareway';
mongoose.connect(mongoURI)
  .then(() => console.log('🟢 [MongoDB] Erfolgreich verbunden!'))
  .catch(err => console.error('🔴 [MongoDB] Verbindungsfehler:', err));
// --------------------------


// --- NEU: ROUTE ZUM ERSTELLEN EINER FAHRT ---
app.post('/api/rides', async (req, res) => {
  try {
    // Erstellt ein neues Dokument basierend auf den Daten, die wir mitsenden
    const newRide = new Ride(req.body);
    
    // In der MongoDB abspeichern
    const savedRide = await newRide.save();
    
    // Status 211 (Created) und das gespeicherte Dokument zurückschicken
    res.status(201).json(savedRide);
  } catch (error) {
    console.error('Fehler beim Speichern:', error);
    res.status(400).json({ message: 'Fehler beim Erstellen der Fahrt', error: error.message });
  }
});


// Erste Test-Route (GET)
app.get('/', (req, res) => {
  res.send('SHAREWAY Backend läuft einwandfrei! 🚀');
});

// Server starten
app.listen(PORT, () => {
  console.log(`[Server] Läuft auf Port ${PORT}`);
});