-- =============================================
-- FAMILY TRACKER - SUPABASE SETUP (CORREGIDO)
-- =============================================

-- 1. HABILITAR EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. CREAR TABLAS
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    fcm_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS circles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS circle_members (
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('owner', 'admin', 'member')) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (circle_id, user_id)
);

CREATE TABLE IF NOT EXISTS locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters INTEGER DEFAULT 100,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS place_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    place_id UUID REFERENCES places(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    arrived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE
);

-- 3. ÍNDICES
CREATE INDEX IF NOT EXISTS idx_locations_user_id ON locations(user_id);
CREATE INDEX IF NOT EXISTS idx_locations_circle_id ON locations(circle_id);
CREATE INDEX IF NOT EXISTS idx_locations_timestamp ON locations(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_places_circle_id ON places(circle_id);
CREATE INDEX IF NOT EXISTS idx_circle_members_user_id ON circle_members(user_id);
CREATE INDEX IF NOT EXISTS idx_circle_members_circle_id ON circle_members(circle_id);
CREATE INDEX IF NOT EXISTS idx_place_visits_user_id ON place_visits(user_id);
CREATE INDEX IF NOT EXISTS idx_place_visits_place_id ON place_visits(place_id);

-- 4. REALTIME
ALTER PUBLICATION supabase_realtime ADD TABLE locations;

-- 5. FUNCIONES
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. RLS - HABILITAR
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE circle_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_visits ENABLE ROW LEVEL SECURITY;

-- 7. POLICIES CORREGIDAS
-- Eliminar policies existentes
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Circle members can view circles" ON circles;
DROP POLICY IF EXISTS "Owners can insert circles" ON circles;
DROP POLICY IF EXISTS "Owners can update circles" ON circles;
DROP POLICY IF EXISTS "Members can view circle members" ON circle_members;
DROP POLICY IF EXISTS "Circle members can view locations" ON locations;
DROP POLICY IF EXISTS "Users can insert own locations" ON locations;
DROP POLICY IF EXISTS "Circle members can view places" ON places;
DROP POLICY IF EXISTS "Circle members can insert places" ON places;
DROP POLICY IF EXISTS "Place owners can update places" ON places;
DROP POLICY IF EXISTS "Place owners can delete places" ON places;
DROP POLICY IF EXISTS "Users can insert place visits" ON place_visits;

-- Nueva policies sin recursión
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Circle members can view circles" ON circles FOR SELECT USING (
    EXISTS (SELECT 1 FROM circle_members WHERE circle_id = circles.id AND user_id = auth.uid())
);
CREATE POLICY "Owners can insert circles" ON circles FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Owners can update circles" ON circles FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Members can view circle members" ON circle_members FOR SELECT USING (
    EXISTS (SELECT 1 FROM circle_members cm WHERE cm.circle_id = circle_members.circle_id AND cm.user_id = auth.uid())
);

CREATE POLICY "Circle members can view locations" ON locations FOR SELECT USING (
    EXISTS (SELECT 1 FROM circle_members WHERE circle_id = locations.circle_id AND user_id = auth.uid())
);
CREATE POLICY "Users can insert own locations" ON locations FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Circle members can view places" ON places FOR SELECT USING (
    EXISTS (SELECT 1 FROM circle_members WHERE circle_id = places.circle_id AND user_id = auth.uid())
);
CREATE POLICY "Circle members can insert places" ON places FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM circle_members WHERE circle_id = places.circle_id AND user_id = auth.uid())
);
CREATE POLICY "Place owners can update places" ON places FOR UPDATE USING (auth.uid() = created_by);
CREATE POLICY "Place owners can delete places" ON places FOR DELETE USING (auth.uid() = created_by);

CREATE POLICY "Users can insert place visits" ON place_visits FOR INSERT WITH CHECK (auth.uid() = user_id);
