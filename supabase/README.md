# Configuración de Supabase

## Ejecutar el Script SQL

1. Ve a tu proyecto en [supabase.com](https://supabase.com/dashboard)
2. Click en **SQL Editor** en el menú lateral
3. Click en **New query**
4. Copia todo el contenido de `setup.sql`
5. Pégalo en el editor
6. Click en **Run**

## Verificar que todo esté correcto

Después de ejecutar, verifica:

### Tablas creadas
- ✅ profiles
- ✅ circles
- ✅ circle_members
- ✅ locations
- ✅ places
- ✅ place_visits

### Extensiones habilitadas
- ✅ uuid-ossp
- ✅ postgis

### Realtime
- La tabla `locations` debe aparecer en **Database → Replication**

## Credenciales para la App

Copia estas credenciales para usar en Flutter:

```
SUPABASE_URL: https://boanunriryulykxdwcte.supabase.co
SUPABASE_ANON_KEY: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvYW51bnJpcnl1bHlreGR3Y3RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3MTU3NzEsImV4cCI6MjA5MDI5MTc3MX0.wHIfb_gqdJ2lAZpvN2EyPeyz_Ors6az0NBgOzCkW_g4
```

## Siguiente Paso

Después de ejecutar el SQL:
1. Ve a **Settings → API**
2. Verifica que las credenciales sean correctas
3. Continúa con Firebase
