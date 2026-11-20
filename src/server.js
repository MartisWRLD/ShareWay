const express = require('express');
const cors = require('cors');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
require('dotenv').config();

// 1. FIREBASE ADMIN INITIALISIERUNG
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount),
  databaseURL: 'https://shareway-f6764-default-rtdb.europe-west1.firebasedatabase.app'
});

const db = getFirestore();
const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Swagger UI unter /api-docs bereitstellen
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// ==========================================
// ROUTEN FÜR RIDES (Firestore)
// ==========================================

// Alle Fahrten abrufen
app.get('/api/rides', async (req, res) => {
  try {
    const snapshot = await db.collection('rides').get();
    const rides = snapshot.docs.map((doc) => ({
      rideId: doc.id,
      ...doc.data()
    }));
    res.status(200).json(rides);
  } catch (error) {
    console.error('Fehler beim Abrufen der Fahrten:', error);
    res.status(500).json({ message: 'Fehler beim Laden der Fahrten', error: error.message });
  }
});

// Neue Fahrt erstellen
app.post('/api/rides', async (req, res) => {
  try {
    const rideData = {
      ...req.body,
      created_at: FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('rides').add(rideData);

    res.status(201).json({
      rideId: docRef.id,
      ...rideData
    });
  } catch (error) {
    console.error('Fehler beim Speichern der Fahrt:', error);
    res.status(400).json({ message: 'Fehler beim Erstellen der Fahrt', error: error.message });
  }
});

// ==========================================
// ROUTEN FÜR USERS (Firestore)
// ==========================================

// User-Profil anlegen / nach Registrierung speichern
app.post('/api/users', async (req, res) => {
  try {
    const { userId, ...userData } = req.body;

    if (userId) {
      await db.collection('users').doc(userId).set({
        ...userData,
        created_at: FieldValue.serverTimestamp()
      });
      return res.status(201).json({ userId, ...userData });
    }

    const docRef = await db.collection('users').add({
      ...userData,
      created_at: FieldValue.serverTimestamp()
    });
    res.status(201).json({ userId: docRef.id, ...userData });
  } catch (error) {
    res.status(400).json({ message: 'Fehler beim Speichern des Users', error: error.message });
  }
});

// ==========================================
// ROUTEN FÜR VEHICLES (Firestore)
// ==========================================

// Neues Fahrzeug anlegen
app.post('/api/vehicles', async (req, res) => {
  try {
    const docRef = await db.collection('vehicles').add(req.body);
    res.status(201).json({
      vehiclesId: docRef.id,
      ...req.body
    });
  } catch (error) {
    res.status(400).json({ message: 'Fehler beim Speichern des Fahrzeugs', error: error.message });
  }
});

// Basis-Test-Route
app.get('/', (req, res) => {
  res.send('SHAREWAY REST-API (Firebase Edition) läuft einwandfrei!');
});

// Server starten
app.listen(PORT, () => {
  console.log(`[Server] Läuft auf Port ${PORT}`);
  console.log(`[Swagger] Dokumentation verfügbar unter http://localhost:${PORT}/api-docs`);
});