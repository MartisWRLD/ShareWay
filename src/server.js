const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');
require('dotenv').config();

// ==========================================
// 1. FIREBASE ADMIN INITIALISIERUNG
// ==========================================
function loadServiceAccount() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  }

  const envPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  const fallbackPath = path.join(__dirname, 'serviceAccountKey.json');
  const targetPath = envPath || fallbackPath;

  if (!fs.existsSync(targetPath)) {
    throw new Error(
      `Kein Firebase Service Account gefunden (${targetPath}). Setze GOOGLE_APPLICATION_CREDENTIALS oder FIREBASE_SERVICE_ACCOUNT_JSON.`
    );
  }

  return JSON.parse(fs.readFileSync(targetPath, 'utf8'));
}

const serviceAccount = loadServiceAccount();

initializeApp({
  credential: cert(serviceAccount),
  databaseURL:
    process.env.FIREBASE_DATABASE_URL ||
    'https://shareway-f6764-default-rtdb.europe-west1.firebasedatabase.app'
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
// ROUTEN FÜR USERS (Firestore)
// ==========================================

// User-Profil anlegen / nach Registrierung speichern
app.post('/api/users', async (req, res) => {
  try {
    const { userId, ...userData } = req.body;

    if (userId) {
      await db
        .collection('users')
        .doc(userId)
        .set(
          {
            ...userData,
            updated_at: FieldValue.serverTimestamp(),
            created_at: FieldValue.serverTimestamp()
          },
          { merge: true }
        );
      return res.status(201).json({ userId, ...userData });
    }

    const docRef = await db.collection('users').add({
      ...userData,
      created_at: FieldValue.serverTimestamp()
    });
    res.status(201).json({ userId: docRef.id, ...userData });
  } catch (error) {
    console.error('Fehler beim Speichern des Users:', error);
    res.status(400).json({ message: 'Fehler beim Speichern des Users', error: error.message });
  }
});

// ==========================================
// ROUTEN FÜR VEHICLES (Firestore)
// ==========================================

// Fahrzeuge abrufen (optional gefiltert nach ?userId=...)
app.get('/api/vehicles', async (req, res) => {
  try {
    const { userId } = req.query;
    let query = db.collection('vehicles');

    if (userId) {
      query = query.where('userId', '==', String(userId));
    }

    const snapshot = await query.get();
    const vehicles = snapshot.docs.map((doc) => ({
      vehiclesId: doc.id,
      ...doc.data()
    }));

    res.status(200).json(vehicles);
  } catch (error) {
    console.error('Fehler beim Abrufen der Fahrzeuge:', error);
    res.status(500).json({ message: 'Fehler beim Laden der Fahrzeuge', error: error.message });
  }
});

// Neues Fahrzeug anlegen (inkl. price_per_km)
app.post('/api/vehicles', async (req, res) => {
  try {
    const body = { ...req.body };

    if (body.price_per_km !== undefined && body.price_per_km !== null && body.price_per_km !== '') {
      body.price_per_km = Number(body.price_per_km);
    }
    if (body.seats_total !== undefined && body.seats_total !== null && body.seats_total !== '') {
      body.seats_total = Number(body.seats_total);
    }

    const vehicleData = {
      ...body,
      created_at: FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('vehicles').add(vehicleData);

    res.status(201).json({
      vehiclesId: docRef.id,
      ...vehicleData
    });
  } catch (error) {
    console.error('Fehler beim Speichern des Fahrzeugs:', error);
    res.status(400).json({ message: 'Fehler beim Speichern des Fahrzeugs', error: error.message });
  }
});

// ==========================================
// ROUTEN FÜR RIDES (Firestore)
// ==========================================

// Fahrten abrufen & optional filtern (Abfahrtszeit / Ankunftszeit optional)
app.get('/api/rides', async (req, res) => {
  try {
    const { from, to, departureTime, arrivalTime, seats } = req.query;
    const snapshot = await db.collection('rides').get();

    let rides = snapshot.docs.map((doc) => ({
      rideId: doc.id,
      ...doc.data()
    }));

    if (from) {
      const needle = String(from).toLowerCase();
      rides = rides.filter((r) => String(r.start_point || r.from || '').toLowerCase().includes(needle));
    }
    if (to) {
      const needle = String(to).toLowerCase();
      rides = rides.filter((r) => String(r.end_point || r.to || '').toLowerCase().includes(needle));
    }
    if (departureTime) {
      rides = rides.filter((r) => String(r.departure_time || '') === String(departureTime));
    }
    if (arrivalTime) {
      rides = rides.filter((r) => String(r.arrival_time || '') === String(arrivalTime));
    }
    if (seats) {
      const minSeats = Number(seats);
      rides = rides.filter((r) => Number(r.seats_available ?? 0) >= minSeats);
    }

    res.status(200).json(rides);
  } catch (error) {
    console.error('Fehler beim Abrufen der Fahrten:', error);
    res.status(500).json({ message: 'Fehler beim Laden der Fahrten', error: error.message });
  }
});

// Neue Fahrt erstellen (arrival_time optional)
app.post('/api/rides', async (req, res) => {
  try {
    const { arrival_time, ...rest } = req.body;

    const rideData = {
      ...rest,
      arrival_time: arrival_time ? arrival_time : null,
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
// ROUTEN FÜR BOOKINGS & MESSAGES (Firestore)
// ==========================================

// Buchung erstellen (inkl. finalem Kostenbetrag)
app.post('/api/bookings', async (req, res) => {
  try {
    const bookingData = {
      ...req.body,
      created_at: FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('bookings').add(bookingData);

    res.status(201).json({
      bookingId: docRef.id,
      ...bookingData
    });
  } catch (error) {
    console.error('Fehler beim Speichern der Buchung:', error);
    res.status(400).json({ message: 'Fehler beim Erstellen der Buchung', error: error.message });
  }
});

// Nachrichten zu einer Buchung abrufen
app.get('/api/bookings/:bookingId/messages', async (req, res) => {
  try {
    const { bookingId } = req.params;
    const snapshot = await db
      .collection('messages')
      .where('bookingId', '==', bookingId)
      .get();

    const messages = snapshot.docs.map((doc) => ({
      messageId: doc.id,
      ...doc.data()
    }));

    res.status(200).json(messages);
  } catch (error) {
    console.error('Fehler beim Abrufen der Nachrichten:', error);
    res.status(500).json({ message: 'Fehler beim Laden der Nachrichten', error: error.message });
  }
});

// Neue Nachricht senden (senderId als normales Attribut)
app.post('/api/messages', async (req, res) => {
  try {
    const { bookingId, senderId, message_text } = req.body;

    if (!bookingId || !senderId || !message_text) {
      return res.status(400).json({
        message: 'bookingId, senderId und message_text sind erforderlich.'
      });
    }

    const messageData = {
      bookingId,
      senderId,
      message_text,
      sent_at: FieldValue.serverTimestamp()
    };

    const docRef = await db.collection('messages').add(messageData);

    res.status(201).json({
      messageId: docRef.id,
      ...messageData
    });
  } catch (error) {
    console.error('Fehler beim Speichern der Nachricht:', error);
    res.status(400).json({ message: 'Fehler beim Senden der Nachricht', error: error.message });
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