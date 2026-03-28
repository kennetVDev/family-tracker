# Family Tracker - Technical Specification

## 1. Project Overview

**Project Name**: Family Tracker  
**Type**: Cross-platform Mobile Application  
**Core Functionality**: GPS location sharing app for small family circles with real-time tracking, geofencing, and notifications.

---

## 2. Technology Stack & Choices

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Riverpod
- **Architecture**: Clean Architecture

### Backend
- **Platform**: Supabase
- **Database**: PostgreSQL with PostGIS extension
- **Authentication**: Supabase Auth (Email + Google OAuth)
- **Real-time**: Supabase Realtime subscriptions
- **Edge Functions**: Deno (for server-side logic)
- **Storage**: Supabase Storage (user avatars)

### External Services
- **Maps**: Google Maps SDK + Places API + Geocoding
- **Push Notifications**: Firebase Cloud Messaging (FCM)

### Key Dependencies (Flutter)
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  google_maps_flutter: ^2.5.0
  geolocator: ^11.0.0
  geocoding: ^3.0.0
  firebase_core: ^3.0.0
  firebase_messaging: ^14.0.0
  flutter_riverpod: ^2.4.0
  go_router: ^13.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
  json_serializable: ^6.7.0
```

---

## 3. Feature List

### Authentication
- [ ] Email/password registration and login
- [ ] Google OAuth sign-in
- [ ] Password reset
- [ ] Session persistence

### Circle Management
- [ ] Create family circle (owner role)
- [ ] Join circle via invite code
- [ ] Leave circle
- [ ] View circle members
- [ ] Maximum 10 members per circle

### Location Tracking
- [ ] Real-time GPS location updates
- [ ] Background location tracking
- [ ] Location history storage
- [ ] Battery-efficient tracking (configurable intervals)

### Geofencing
- [ ] Create custom places (home, school, work)
- [ ] Set geofence radius for each place
- [ ] Detect entry/exit events
- [ ] Push notifications on place events

### Maps & UI
- [ ] Interactive map with all member locations
- [ ] Custom markers for each member
- [ ] Place markers on map
- [ ] Current location button
- [ ] Member list panel

### History & Analytics
- [ ] View location history by day
- [ ] Place visit history
- [ ] Time spent at each place

### Settings
- [ ] User profile (name, avatar)
- [ ] Location sharing toggle
- [ ] Notification preferences
- [ ] Tracking interval configuration

---

## 4. UI/UX Design Direction

### Visual Style
- **Design System**: Material Design 3
- **Theme**: Light mode with family-friendly colors
- **Primary Color**: #4CAF50 (Green - safety/trust)
- **Secondary Color**: #2196F3 (Blue - communication)
- **Accent Color**: #FF9800 (Orange - alerts)

### Color Palette
```
Primary: #4CAF50 (Green)
Primary Variant: #388E3C
Secondary: #2196F3 (Blue)
Background: #FAFAFA
Surface: #FFFFFF
Error: #F44336
On Primary: #FFFFFF
On Background: #212121
```

### Layout Approach
- **Navigation**: Bottom navigation bar with 4 tabs
  1. Map (home)
  2. Members
  3. Places
  4. Settings
- **Map**: Full-screen map as primary view
- **Lists**: Card-based design for members and places
- **Forms**: Bottom sheets for creating/editing items

### Key Screens
1. **Splash Screen** - App logo + auth check
2. **Auth Screen** - Login/Register tabs
3. **Create/Join Circle** - Onboarding flow
4. **Main Map** - Primary map view with members
5. **Member List** - Circle members with status
6. **Place List** - Saved places with geofences
7. **Place Detail** - Place info + visit history
8. **Settings** - User and app settings

---

## 5. Database Schema

### Tables

```sql
-- Users (extends Supabase auth.users)
profiles (
  id UUID PRIMARY KEY REFERENCES auth.users,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  fcm_token TEXT,
  created_at TIMESTAMP
)

-- Circles (family groups)
circles (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  owner_id UUID REFERENCES profiles,
  invite_code TEXT UNIQUE,
  created_at TIMESTAMP
)

-- Circle members
circle_members (
  circle_id UUID REFERENCES circles,
  user_id UUID REFERENCES profiles,
  role TEXT CHECK (role IN ('owner', 'admin', 'member')),
  joined_at TIMESTAMP,
  PRIMARY KEY (circle_id, user_id)
)

-- Location history
locations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES profiles,
  circle_id UUID REFERENCES circles,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  accuracy DOUBLE PRECISION,
  timestamp TIMESTAMP DEFAULT NOW()
)

-- Saved places (geofences)
places (
  id UUID PRIMARY KEY,
  circle_id UUID REFERENCES circles,
  name TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  radius_meters INTEGER DEFAULT 100,
  created_by UUID REFERENCES profiles,
  created_at TIMESTAMP
)

-- Place visits (when members enter/exit)
place_visits (
  id UUID PRIMARY KEY,
  place_id UUID REFERENCES places,
  user_id UUID REFERENCES profiles,
  arrived_at TIMESTAMP,
  left_at TIMESTAMP
)
```

---

## 6. API Endpoints (Edge Functions)

| Function | Purpose |
|----------|---------|
| `create-circle` | Create new circle with invite code |
| `join-circle` | Join existing circle via code |
| `leave-circle` | Leave current circle |
| `on-location-update` | Triggered on new location insert |
| `check-geofence` | Check if location triggers any geofence |
| `send-push` | Send FCM push notification |

---

## 7. Security

- **Row Level Security (RLS)**: All tables protected
- **Circle isolation**: Users only see their circle data
- **Location privacy**: Users can toggle sharing off
- **Invite codes**: 6-character random codes

---

## 8. Performance Targets

- Location update frequency: Every 30 seconds (configurable)
- Map render: < 100ms
- Geofence check: < 50ms
- Push notification delivery: < 1 second
- App cold start: < 3 seconds
