-- =============================================
-- FAMILY TRACKER - SUPABASE SETUP
-- Ejecuta este script en el Editor SQL de Supabase
-- =============================================

-- 1. HABILITAR EXTENSIONES
-- =========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. CREAR TABLAS
-- ===============

-- Tabla de perfiles (extiende auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    fcm_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de círculos (grupos familiares)
CREATE TABLE circles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    owner_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de miembros del círculo
CREATE TABLE circle_members (
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('owner', 'admin', 'member')) DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (circle_id, user_id)
);

-- Tabla de ubicaciones
CREATE TABLE locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de lugares (geofences)
CREATE TABLE places (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    circle_id UUID REFERENCES circles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters INTEGER DEFAULT 100,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de visitas a lugares
CREATE TABLE place_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    place_id UUID REFERENCES places(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    arrived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE
);

-- 3. CREAR ÍNDICES PARA MEJORAR RENDIMIENTO
-- ==========================================
CREATE INDEX idx_locations_user_id ON locations(user_id);
CREATE INDEX idx_locations_circle_id ON locations(circle_id);
CREATE INDEX idx_locations_timestamp ON locations(timestamp DESC);
CREATE INDEX idx_places_circle_id ON places(circle_id);
CREATE INDEX idx_circle_members_user_id ON circle_members(user_id);
CREATE INDEX idx_circle_members_circle_id ON circle_members(circle_id);
CREATE INDEX idx_place_visits_user_id ON place_visits(user_id);
CREATE INDEX idx_place_visits_place_id ON place_visits(place_id);

-- 4. HABILITAR REALTIME EN TABLA LOCATIONS
-- ==========================================
ALTER PUBLICATION supabase_realtime ADD TABLE locations;

-- 5. CREAR FUNCIONES AUXILIARES
-- =============================

-- Función para generar código de invitación aleatorio
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Función para crear perfil automáticamente cuando se registra usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil al registrar usuario
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. CONFIGURAR ROW LEVEL SECURITY (RLS)
-- ======================================

-- Habilitar RLS en todas las tablas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE circle_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE places ENABLE ROW LEVEL SECURITY;
ALTER TABLE place_visits ENABLE ROW LEVEL SECURITY;

-- Policies para profiles
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Policies para circles
CREATE POLICY "Circle members can view circles" ON circles
    FOR SELECT USING (
        id IN (SELECT circle_id FROM circle_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Owners can insert circles" ON circles
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update circles" ON circles
    FOR UPDATE USING (auth.uid() = owner_id);

-- Policies para circle_members
CREATE POLICY "Members can view circle members" ON circle_members
    FOR SELECT USING (
        circle_id IN (SELECT circle_id FROM circle_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Members can join circles" ON circle_members
    FOR INSERT WITH CHECK (
        circle_id IN (SELECT id FROM circles WHERE invite_code = (
            SELECT invite_code FROM circles WHERE id = circle_id
        ))
    );

-- Policies para locations
CREATE POLICY "Circle members can view locations" ON locations
    FOR SELECT USING (
        circle_id IN (SELECT circle_id FROM circle_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can insert own locations" ON locations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own locations" ON locations
    FOR UPDATE USING (auth.uid() = user_id);

-- Policies para places
CREATE POLICY "Circle members can view places" ON places
    FOR SELECT USING (
        circle_id IN (SELECT circle_id FROM circle_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Circle members can insert places" ON places
    FOR INSERT WITH CHECK (
        circle_id IN (SELECT circle_id FROM circle_members WHERE user_id = auth.uid())
    );

CREATE POLICY "Place owners can update places" ON places
    FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Place owners can delete places" ON places
    FOR DELETE USING (auth.uid() = created_by);

-- Policies para place_visits
CREATE POLICY "Circle members can view place visits" ON place_visits
    FOR SELECT USING (
        place_id IN (SELECT id FROM places WHERE circle_id IN (
            SELECT circle_id FROM circle_members WHERE user_id = auth.uid()
        ))
    );

CREATE POLICY "Users can insert place visits" ON place_visits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 7. CREAR FUNCIONES PARA GEOFENCING
-- ===================================

-- Función para calcular distancia entre dos puntos (en metros)
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    earth_radius_meters DOUBLE PRECISION := 6371000;
    d_lat DOUBLE PRECISION;
    d_lon DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    d_lat := radians(lat2 - lat1);
    d_lon := radians(lon2 - lon1);
    a := sin(d_lat/2) * sin(d_lat/2) +
         cos(radians(lat1)) * cos(radians(lat2)) *
         sin(d_lon/2) * sin(d_lon/2);
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    RETURN earth_radius_meters * c;
END;
$$ LANGUAGE plpgsql;

-- Función para verificar si una ubicación está dentro de un lugar
CREATE OR REPLACE FUNCTION is_inside_place(
    p_lat DOUBLE PRECISION,
    p_lon DOUBLE PRECISION,
    place_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_lat DOUBLE PRECISION;
    v_lon DOUBLE PRECISION;
    v_radius INTEGER;
    v_distance DOUBLE PRECISION;
BEGIN
    SELECT latitude, longitude, radius_meters
    INTO v_lat, v_lon, v_radius
    FROM places WHERE id = place_id;

    IF v_lat IS NULL THEN
        RETURN FALSE;
    END IF;

    v_distance := calculate_distance(p_lat, p_lon, v_lat, v_lon);
    RETURN v_distance <= v_radius;
END;
$$ LANGUAGE plpgsql;

-- 8. CONFIGURAR STORAGE PARA AVATARES
-- ====================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Anyone can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload avatars" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete avatars" ON storage.objects
    FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- =============================================
-- CONFIGURACIÓN COMPLETA
-- =============================================
