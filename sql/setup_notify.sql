-- Run this SQL in your PostGIS database to enable LISTEN/NOTIFY for tile updates.
-- Adjust the table name and columns to match your schema.

-- Generic trigger function that sends notifications on INSERT/UPDATE/DELETE
CREATE OR REPLACE FUNCTION notify_tile_update()
RETURNS trigger AS $$
DECLARE
    payload TEXT;
    layer_name TEXT;
    feature_id BIGINT;
BEGIN
    -- The layer name is passed via TG_ARGV[0]
    layer_name := TG_ARGV[0];

    IF TG_OP = 'DELETE' THEN
        feature_id := OLD.id;
        -- For DELETE, include old bounds so affected tiles can be cleared
        payload := json_build_object(
            'layer', layer_name,
            'id', feature_id,
            'op', 'delete',
            'old_bounds', json_build_object(
                'min_lon', ST_XMin(ST_Envelope(ST_Transform(OLD.geom, 4326))),
                'min_lat', ST_YMin(ST_Envelope(ST_Transform(OLD.geom, 4326))),
                'max_lon', ST_XMax(ST_Envelope(ST_Transform(OLD.geom, 4326))),
                'max_lat', ST_YMax(ST_Envelope(ST_Transform(OLD.geom, 4326)))
            )
        )::TEXT;
    ELSIF TG_OP = 'UPDATE' THEN
        feature_id := NEW.id;
        -- For UPDATE, include old bounds so tiles at old location are also refreshed
        payload := json_build_object(
            'layer', layer_name,
            'id', feature_id,
            'op', 'update',
            'old_bounds', json_build_object(
                'min_lon', ST_XMin(ST_Envelope(ST_Transform(OLD.geom, 4326))),
                'min_lat', ST_YMin(ST_Envelope(ST_Transform(OLD.geom, 4326))),
                'max_lon', ST_XMax(ST_Envelope(ST_Transform(OLD.geom, 4326))),
                'max_lat', ST_YMax(ST_Envelope(ST_Transform(OLD.geom, 4326)))
            )
        )::TEXT;
    ELSE
        -- INSERT
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

-- Example: attach the trigger to a 'buildings' table
-- Change 'buildings' to your actual table name
-- The argument 'buildings' must match the layer name in config.toml
DROP TRIGGER IF EXISTS tile_update_trigger ON buildings;
CREATE TRIGGER tile_update_trigger
    AFTER INSERT OR UPDATE OR DELETE ON buildings
    FOR EACH ROW
    EXECUTE FUNCTION notify_tile_update('buildings');

-- To add more tables, just create additional triggers:
-- DROP TRIGGER IF EXISTS tile_update_trigger ON roads;
-- CREATE TRIGGER tile_update_trigger
--     AFTER INSERT OR UPDATE OR DELETE ON roads
--     FOR EACH ROW
--     EXECUTE FUNCTION notify_tile_update('roads');
