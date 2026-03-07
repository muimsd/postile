-- Example: local-parks
-- Creates a PostGIS database with sample park and trail data,
-- then installs LISTEN/NOTIFY triggers for incremental tile updates.

CREATE EXTENSION IF NOT EXISTS postgis;

-- Parks layer: polygons
CREATE TABLE IF NOT EXISTS parks (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'park',
    geom geometry(Polygon, 4326) NOT NULL
);

-- Trails layer: linestrings
CREATE TABLE IF NOT EXISTS trails (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    difficulty TEXT NOT NULL DEFAULT 'easy',
    length_km DOUBLE PRECISION,
    geom geometry(LineString, 4326) NOT NULL
);

-- Spatial indexes
CREATE INDEX IF NOT EXISTS idx_parks_geom ON parks USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_trails_geom ON trails USING GIST (geom);

-- Sample parks (San Francisco area)
INSERT INTO parks (name, type, geom) VALUES
    ('Golden Gate Park', 'urban_park', ST_GeomFromText('POLYGON((-122.5107 37.7694, -122.4534 37.7694, -122.4534 37.7749, -122.5107 37.7749, -122.5107 37.7694))', 4326)),
    ('Dolores Park', 'neighborhood_park', ST_GeomFromText('POLYGON((-122.4280 37.7596, -122.4252 37.7596, -122.4252 37.7616, -122.4280 37.7616, -122.4280 37.7596))', 4326)),
    ('Presidio', 'national_park', ST_GeomFromText('POLYGON((-122.4710 37.7880, -122.4440 37.7880, -122.4440 37.8020, -122.4710 37.8020, -122.4710 37.7880))', 4326)),
    ('Buena Vista Park', 'neighborhood_park', ST_GeomFromText('POLYGON((-122.4420 37.7680, -122.4380 37.7680, -122.4380 37.7710, -122.4420 37.7710, -122.4420 37.7680))', 4326)),
    ('Glen Canyon Park', 'urban_park', ST_GeomFromText('POLYGON((-122.4430 37.7380, -122.4370 37.7380, -122.4370 37.7430, -122.4430 37.7430, -122.4430 37.7380))', 4326));

-- Sample trails
INSERT INTO trails (name, difficulty, length_km, geom) VALUES
    ('Lands End Trail', 'moderate', 5.4, ST_GeomFromText('LINESTRING(-122.5110 37.7878, -122.5050 37.7870, -122.4980 37.7850, -122.4940 37.7830)', 4326)),
    ('Batteries to Bluffs', 'hard', 2.1, ST_GeomFromText('LINESTRING(-122.4830 37.7990, -122.4790 37.7960, -122.4750 37.7940)', 4326)),
    ('Crosstown Trail', 'easy', 27.4, ST_GeomFromText('LINESTRING(-122.5030 37.7110, -122.4700 37.7300, -122.4400 37.7500, -122.4100 37.7700, -122.3950 37.7850)', 4326)),
    ('Glen Park Loop', 'easy', 1.8, ST_GeomFromText('LINESTRING(-122.4430 37.7380, -122.4400 37.7400, -122.4370 37.7420, -122.4400 37.7430, -122.4430 37.7380)', 4326));

-- Install the notify trigger function
CREATE OR REPLACE FUNCTION notify_tile_update()
RETURNS trigger AS $$
DECLARE
    payload TEXT;
    layer_name TEXT;
    feature_id BIGINT;
BEGIN
    layer_name := TG_ARGV[0];

    IF TG_OP = 'DELETE' THEN
        feature_id := OLD.id;
        payload := json_build_object(
            'layer', layer_name,
            'id', feature_id,
            'op', 'delete',
            'old_bounds', json_build_object(
                'min_lon', ST_XMin(ST_Envelope(OLD.geom)),
                'min_lat', ST_YMin(ST_Envelope(OLD.geom)),
                'max_lon', ST_XMax(ST_Envelope(OLD.geom)),
                'max_lat', ST_YMax(ST_Envelope(OLD.geom))
            )
        )::TEXT;
    ELSIF TG_OP = 'UPDATE' THEN
        feature_id := NEW.id;
        payload := json_build_object(
            'layer', layer_name,
            'id', feature_id,
            'op', 'update',
            'old_bounds', json_build_object(
                'min_lon', ST_XMin(ST_Envelope(OLD.geom)),
                'min_lat', ST_YMin(ST_Envelope(OLD.geom)),
                'max_lon', ST_XMax(ST_Envelope(OLD.geom)),
                'max_lat', ST_YMax(ST_Envelope(OLD.geom))
            )
        )::TEXT;
    ELSE
        feature_id := NEW.id;
        payload := json_build_object(
            'layer', layer_name,
            'id', feature_id,
            'op', 'insert'
        )::TEXT;
    END IF;

    PERFORM pg_notify('tile_update', payload);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach triggers
DROP TRIGGER IF EXISTS tile_update_trigger ON parks;
CREATE TRIGGER tile_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON parks
    FOR EACH ROW
    EXECUTE FUNCTION notify_tile_update('parks');

DROP TRIGGER IF EXISTS tile_update_trigger ON trails;
CREATE TRIGGER tile_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON trails
    FOR EACH ROW
    EXECUTE FUNCTION notify_tile_update('trails');
