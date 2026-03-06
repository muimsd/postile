use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
pub struct AppConfig {
    pub database: DatabaseConfig,
    pub server: ServerConfig,
    pub tiles: TilesConfig,
    #[serde(default)]
    pub cache: CacheConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct DatabaseConfig {
    pub host: String,
    pub port: u16,
    pub user: String,
    pub password: String,
    pub dbname: String,
    pub pool_size: Option<usize>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

#[derive(Debug, Clone, Deserialize)]
pub struct TilesConfig {
    pub mbtiles_path: String,
    pub min_zoom: u8,
    pub max_zoom: u8,
    pub layers: Vec<LayerConfig>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct LayerConfig {
    pub name: String,
    pub schema: Option<String>,
    pub table: String,
    pub geometry_column: Option<String>,
    pub id_column: Option<String>,
    pub srid: Option<i32>,
    pub properties: Option<Vec<String>>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct CacheConfig {
    pub max_tiles: Option<usize>,
    pub debounce_ms: Option<u64>,
}

impl Default for CacheConfig {
    fn default() -> Self {
        Self {
            max_tiles: Some(10_000),
            debounce_ms: Some(200),
        }
    }
}

impl DatabaseConfig {
    pub fn connection_string(&self) -> String {
        format!(
            "host={} port={} user={} password={} dbname={}",
            self.host, self.port, self.user, self.password, self.dbname
        )
    }
}

impl Default for ServerConfig {
    fn default() -> Self {
        Self {
            host: "0.0.0.0".to_string(),
            port: 3000,
        }
    }
}

pub fn load_config(path: &str) -> anyhow::Result<AppConfig> {
    let settings = config::Config::builder()
        .add_source(config::File::with_name(path))
        .add_source(config::Environment::with_prefix("TILES"))
        .build()?;

    let cfg: AppConfig = settings.try_deserialize()?;
    Ok(cfg)
}
