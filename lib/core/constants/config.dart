// Configuration file for Family Tracker App
// Update these values with your actual credentials

class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://boanunriryulykxdwcte.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvYW51bnJpcnl1bHlreGR3Y3RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3MTU3NzEsImV4cCI6MjA5MDI5MTc3MX0.wHIfb_gqdJ2lAZpvN2EyPeyz_Ors6az0NBgOzCkW_g4';
  
  // Google Maps API Key
  static const String googleMapsApiKey = 'AIzaSyCEy3vUznOizf9_QujUWVpAIeUkt6A3sqA';
  
  // Firebase Configuration (Android)
  static const String androidPackageName = 'com.familytracker.family_tracker';
  
  // Location Settings
  static const int locationUpdateIntervalSeconds = 30;
  static const int locationDistanceFilterMeters = 10;
  static const int defaultGeofenceRadiusMeters = 100;
  
  // App Limits
  static const int maxCircleMembers = 10;
  static const int inviteCodeLength = 6;
}
