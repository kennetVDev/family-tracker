class AppConstants {
  static const String appName = 'Family Tracker';
  
  // Supabase
  static const String supabaseUrl = 'https://boanunriryulykxdwcte.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvYW51bnJpcnl1bHlreGR3Y3RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3MTU3NzEsImV4cCI6MjA5MDI5MTc3MX0.wHIfb_gqdJ2lAZpvN2EyPeyz_Ors6az0NBgOzCkW_g4';
  
  // Google Maps
  static const String googleMapsApiKey = 'AIzaSyC-NM8BMk5pOX-VLlCKRK8q2UxsfMkzSwA';
  
  // Location settings
  static const int locationUpdateInterval = 30; // seconds
  static const int locationDistanceFilter = 10; // meters
  
  // Geofence
  static const int defaultGeofenceRadius = 100; // meters
  
  // Limits
  static const int maxCircleMembers = 10;
  static const int inviteCodeLength = 6;
}
