# Using OGR_FDW for External Data Sources

[OGR_FDW](https://github.com/pramsey/pgsql-ogr-fdw) is a PostgreSQL Foreign Data Wrapper that exposes any OGR-supported data source as a regular table. This lets tilefeed generate vector tiles from Esri FeatureServer, SQL Server, GeoPackage, shapefiles, WFS, and dozens of other formats -- without any code changes.

## How it works

```
Esri FeatureServer ──┐
SQL Server (via TDS) ─┤── OGR_FDW ── PostgreSQL foreign table ── tilefeed ── MBTiles
GeoPackage / SHP ─────┘
```

OGR_FDW creates foreign tables that look and query like regular PostGIS tables. Since tilefeed reads from PostGIS, it works transparently against these tables.

## Setup

```sql
-- Install the extension
CREATE EXTENSION ogr_fdw;

-- Example 1: Esri FeatureServer
CREATE SERVER esri_server
    FOREIGN DATA WRAPPER ogr_fdw
    OPTIONS (
        datasource 'https://services.arcgis.com/ORG_ID/arcgis/rest/services/MyService/FeatureServer/0',
        format 'ESRIJSON'
    );

IMPORT FOREIGN SCHEMA ogr_all
    FROM SERVER esri_server
    INTO public;

-- Example 2: SQL Server via ODBC
CREATE SERVER mssql_server
    FOREIGN DATA WRAPPER ogr_fdw
    OPTIONS (
        datasource 'MSSQL:server=db.example.com;database=geodata;uid=user;pwd=pass',
        format 'MSSQLSpatial'
    );

IMPORT FOREIGN SCHEMA ogr_all
    FROM SERVER mssql_server
    INTO public;

-- Example 3: GeoPackage file
CREATE SERVER gpkg_server
    FOREIGN DATA WRAPPER ogr_fdw
    OPTIONS (
        datasource '/data/parcels.gpkg',
        format 'GPKG'
    );

IMPORT FOREIGN SCHEMA ogr_all
    FROM SERVER gpkg_server
    INTO public;
```

Use `ogr_fdw_info` to discover available layers and columns before importing:

```bash
ogr_fdw_info -s 'https://services.arcgis.com/.../FeatureServer/0'
```

## tilefeed config

Point tilefeed layers at the foreign tables just like any other table:

```toml
[[sources]]
name = "external"
mbtiles_path = "./external.mbtiles"
min_zoom = 0
max_zoom = 14

[[sources.layers]]
name = "parcels"
table = "parcels"          # the foreign table name
geometry_column = "geom"
id_column = "ogc_fid"
srid = 4326
properties = ["owner", "area_sqm", "land_use"]
```

## Considerations

- **No LISTEN/NOTIFY for foreign tables.** Changes happen on the remote side, so PostgreSQL triggers won't fire. Use `tilefeed generate` on a schedule (cron) instead of `tilefeed watch` for these sources.
- **Performance depends on the remote source.** OGR_FDW can push down simple filters, but complex spatial queries may pull entire datasets over the network. For large remote sources, consider materializing the foreign table periodically:
  ```sql
  CREATE MATERIALIZED VIEW parcels_local AS SELECT * FROM parcels;
  REFRESH MATERIALIZED VIEW CONCURRENTLY parcels_local;
  ```
  Then point tilefeed at the materialized view and attach a trigger to refresh + notify.
- **Mixed sources work well.** You can have some sources backed by local PostGIS tables (with LISTEN/NOTIFY for real-time updates) and others backed by OGR_FDW foreign tables (with scheduled `generate` runs). Each `[[sources]]` block operates independently.
