use lru::LruCache;
use std::num::NonZeroUsize;
use std::sync::atomic::{AtomicU64, Ordering};
use tokio::sync::Mutex;

use crate::tiles::TileCoord;

pub struct TileCache {
    inner: Mutex<LruCache<(u8, u32, u32), CachedTile>>,
    hits: AtomicU64,
    misses: AtomicU64,
}

#[derive(Clone)]
pub struct CachedTile {
    pub data: Vec<u8>,
    pub etag: String,
}

impl TileCache {
    pub fn new(capacity: usize) -> Self {
        let cap = NonZeroUsize::new(capacity).unwrap_or(NonZeroUsize::new(1).unwrap());
        Self {
            inner: Mutex::new(LruCache::new(cap)),
            hits: AtomicU64::new(0),
            misses: AtomicU64::new(0),
        }
    }

    pub async fn get(&self, z: u8, x: u32, y: u32) -> Option<CachedTile> {
        let mut cache = self.inner.lock().await;
        let result = cache.get(&(z, x, y)).cloned();
        if result.is_some() {
            self.hits.fetch_add(1, Ordering::Relaxed);
        } else {
            self.misses.fetch_add(1, Ordering::Relaxed);
        }
        result
    }

    pub async fn put(&self, z: u8, x: u32, y: u32, data: Vec<u8>) {
        let etag = compute_etag(&data);
        let mut cache = self.inner.lock().await;
        cache.put((z, x, y), CachedTile { data, etag });
    }

    pub async fn invalidate(&self, tiles: &[TileCoord]) {
        let mut cache = self.inner.lock().await;
        for t in tiles {
            cache.pop(&(t.z, t.x, t.y));
        }
    }

    pub fn stats(&self) -> (u64, u64) {
        (
            self.hits.load(Ordering::Relaxed),
            self.misses.load(Ordering::Relaxed),
        )
    }
}

fn compute_etag(data: &[u8]) -> String {
    use std::hash::{Hash, Hasher};
    let mut hasher = std::collections::hash_map::DefaultHasher::new();
    data.hash(&mut hasher);
    format!("\"{}\"", hasher.finish())
}
