# Family Tracker - Agentes Configuration

## Project Context
- **Project**: Family Tracker - GPS location sharing app for families
- **Stack**: Flutter 3.x + Riverpod + Supabase + Google Maps
- **Architecture**: Clean Architecture (data/repositories, presentation/providers, core/services)

## Key Commands
```bash
flutter run
flutter build apk --debug
flutter build apk --release
```

## Tech Stack
- Frontend: Flutter/Dart, Riverpod (state), go_router (navigation)
- Backend: Supabase (PostgreSQL + PostGIS, Auth, Realtime)
- Maps: Google Maps SDK + Places API + Geocoding
- Push: Firebase Cloud Messaging

## Features Status
- Authentication: Email + Google OAuth
- Circle Management: Create/join circle with invite codes
- Location Tracking: Real-time GPS with background support
- Geofencing: Custom places with entry/exit detection
- Maps: Interactive map with member locations
- Settings: Profile, location sharing toggle, notifications

## Database
- Tables: profiles, circles, circle_members, locations, places, place_visits
- RLS enabled for security

## Code Structure
- lib/core/ - Theme, widgets, services, utils
- lib/data/ - Models, repositories
- lib/presentation/ - Pages, providers
