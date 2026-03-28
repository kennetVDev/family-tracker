# Family Tracker

A family GPS tracking app with real-time location sharing, geofencing, and notifications.

## Features

- Real-time GPS tracking
- Family circles (up to 10 members)
- Geofencing with place notifications
- Location history
- Push notifications

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL, Edge Functions, Realtime)
- **Maps**: Google Maps SDK
- **Push**: Firebase Cloud Messaging (FCM)

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Node.js 18+ (for Supabase CLI)
- Supabase project
- Firebase project
- Google Maps API Key

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment variables:
   - Create `.env` file with:
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_anon_key
     GOOGLE_MAPS_API_KEY=your_maps_api_key
     ```

4. Add Firebase config:
   - `android/app/google-services.json` (Android)
   - `ios/Runner/GoogleService-Info.plist` (iOS)

5. Run the app:
   ```bash
   flutter run
   ```

## Architecture

This project uses Clean Architecture with:
- **Data Layer**: Repositories, Data Sources, Models
- **Domain Layer**: Entities, Use Cases
- **Presentation Layer**: Pages, Widgets, Providers

## License

MIT
