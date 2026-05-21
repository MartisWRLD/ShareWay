const mongoose = require('mongoose');

// Unter-Schema für die Zwischenstopps (Waypoints)
const waypointSchema = new mongoose.Schema({
  stop_name: { type: String, required: true },
  lat: { type: Number, required: true },
  lon: { type: Number, required: true },
  stop_order: { type: Number, required: true }
});

// Haupt-Schema für die Fahrt
const rideSchema = new mongoose.Schema({
  driverId: { 
    type: mongoose.Schema.Types.ObjectId, // Verweis auf ein User-Dokument
    required: true 
  },
  vehicle_info: { type: String, default: '' },
  
  // Start- und Zielort
  start_name: { type: String, required: true },
  lat_start: { type: Number, required: true },
  lon_start: { type: Number, required: true },
  
  destination: { type: String, required: true },
  lat_end: { type: Number, required: true },
  lon_end: { type: Number, required: true },
  
  departure_time: { type: Date, required: true },
  seats_total: { type: Number, required: true },
  
  //  Waypoints direkt als Array
  waypoints: [waypointSchema],
  
  created_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Ride', rideSchema);