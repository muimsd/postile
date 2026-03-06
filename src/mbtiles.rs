use anyhow::{Context, Result};
use rusqlite::{params, Connection};
use std::path::Path;
use tracing::info;

pub struct MbtilesStore {
    conn: Connection,
}

impl MbtilesStore {
    /// Open an existing MBTiles file, materializing the tiles view if needed
    pub fn open(path: &str) -> Result<Self> {
        let conn = Connection::open(path)
            .with_context(|| format!("Failed to open MBTiles at {}", path))?;

        // Tippecanoe creates a `tiles` view over `map` + `images` tables.
        // Materialize it into a real table so we can INSERT/UPDATE/DELETE.
        let is_view: bool = conn
            .query_row(
                "SELECT type = 'view' FROM sqlite_master WHERE name = 'tiles'",
                [],
                |row| row.get(0),
            )
            .unwrap_or(false);

        if is_view {
            info!("Materializing tiles view into a writable table");
            conn.execute_batch(
                "
                CREATE TABLE tiles_real (
                    zoom_level INTEGER NOT NULL,
                    tile_column INTEGER NOT NULL,
                    tile_row INTEGER NOT NULL,
                    tile_data BLOB,
                    UNIQUE (zoom_level, tile_column, tile_row)
                );
                INSERT INTO tiles_real SELECT * FROM tiles;
                DROP VIEW tiles;
                ALTER TABLE tiles_real RENAME TO tiles;
                CREATE INDEX IF NOT EXISTS idx_tiles ON tiles (zoom_level, tile_column, tile_row);
                ",
            )?;
            info!("Tiles view materialized successfully");
        }

        Ok(Self { conn })
    }

    /// Create a new MBTiles file with the required schema
    pub fn create(path: &str) -> Result<Self> {
        if Path::new(path).exists() {
            std::fs::remove_file(path)?;
        }

        let conn = Connection::open(path)
            .with_context(|| format!("Failed to create MBTiles at {}", path))?;

        conn.execute_batch(
            "
            CREATE TABLE metadata (
                name TEXT NOT NULL,
                value TEXT NOT NULL,
                UNIQUE (name)
            );

            CREATE TABLE tiles (
                zoom_level INTEGER NOT NULL,
                tile_column INTEGER NOT NULL,
                tile_row INTEGER NOT NULL,
                tile_data BLOB,
                UNIQUE (zoom_level, tile_column, tile_row)
            );

            CREATE INDEX idx_tiles ON tiles (zoom_level, tile_column, tile_row);
            ",
        )?;

        info!("Created new MBTiles file at {}", path);
        Ok(Self { conn })
    }

    /// Set metadata value
    pub fn set_metadata(&self, name: &str, value: &str) -> Result<()> {
        self.conn.execute(
            "INSERT OR REPLACE INTO metadata (name, value) VALUES (?1, ?2)",
            params![name, value],
        )?;
        Ok(())
    }

    /// Get a tile's data
    pub fn get_tile(&self, z: u8, x: u32, y: u32) -> Result<Option<Vec<u8>>> {
        // MBTiles uses TMS y-coordinate (flipped)
        let tms_y = (1u32 << z) - 1 - y;

        let mut stmt = self.conn.prepare(
            "SELECT tile_data FROM tiles WHERE zoom_level = ?1 AND tile_column = ?2 AND tile_row = ?3",
        )?;

        let result = stmt.query_row(params![z as i32, x as i32, tms_y as i32], |row| {
            row.get::<_, Vec<u8>>(0)
        });

        match result {
            Ok(data) => Ok(Some(data)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e.into()),
        }
    }

    /// Insert or replace a tile
    pub fn put_tile(&self, z: u8, x: u32, y: u32, data: &[u8]) -> Result<()> {
        // MBTiles uses TMS y-coordinate (flipped)
        let tms_y = (1u32 << z) - 1 - y;

        self.conn.execute(
            "INSERT OR REPLACE INTO tiles (zoom_level, tile_column, tile_row, tile_data) VALUES (?1, ?2, ?3, ?4)",
            params![z as i32, x as i32, tms_y as i32, data],
        )?;

        Ok(())
    }

    /// Delete a tile
    pub fn delete_tile(&self, z: u8, x: u32, y: u32) -> Result<()> {
        let tms_y = (1u32 << z) - 1 - y;

        self.conn.execute(
            "DELETE FROM tiles WHERE zoom_level = ?1 AND tile_column = ?2 AND tile_row = ?3",
            params![z as i32, x as i32, tms_y as i32],
        )?;

        Ok(())
    }

    /// Write default metadata for vector tiles
    pub fn write_default_metadata(&self, name: &str, description: &str) -> Result<()> {
        self.set_metadata("name", name)?;
        self.set_metadata("format", "pbf")?;
        self.set_metadata("type", "overlay")?;
        self.set_metadata("version", "2")?;
        self.set_metadata("description", description)?;
        self.set_metadata("scheme", "tms")?;
        Ok(())
    }

    /// Begin a transaction for batch operations
    pub fn begin_transaction(&self) -> Result<()> {
        self.conn.execute("BEGIN TRANSACTION", [])?;
        Ok(())
    }

    /// Commit the current transaction
    pub fn commit_transaction(&self) -> Result<()> {
        self.conn.execute("COMMIT", [])?;
        Ok(())
    }

    /// Rollback the current transaction
    pub fn rollback_transaction(&self) -> Result<()> {
        self.conn.execute("ROLLBACK", [])?;
        Ok(())
    }
}
