# Tile Serving

tilefeed includes a built-in HTTP tile server for development and production use.

## Built-in Server

Start the server with the `serve` command, which generates tiles, starts an HTTP server, and watches for incremental updates:

```bash
tilefeed serve
tilefeed -c myconfig.toml serve
```

### Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /{source}/{z}/{x}/{y}.pbf` | Serve a vector tile (MVT protobuf) |
| `GET /{source}.json` | TileJSON 3.0.0 metadata |
| `GET /health` | Health check (returns `ok`) |

### Features

- **ETags** — SHA-256 based content hashing with `If-None-Match` / 304 Not Modified support
- **CORS** — Configurable origins or wildcard (default)
- **Cache-Control** — `public, max-age=300` on tile responses
- **TileJSON 3.0.0** — Auto-generated from source config, includes derived layers (`_labels`, `_boundary`)

### Configuration

```toml
[serve]
host = "0.0.0.0"     # bind address (default: 127.0.0.1)
port = 3000           # port (default: 3000)
cors_origins = ["http://localhost:8080"]  # omit for wildcard
```

## External Tile Servers

You can also serve MBTiles files produced by tilefeed with external tools:

- **CDN (CloudFront, Cloudflare R2)** — upload via S3 or command backend and serve through CDN
- **Martin** — point [Martin](https://github.com/maplibre/martin) at the MBTiles file for hot-reload
- **tileserver-gl** — use [tileserver-gl](https://github.com/maptiler/tileserver-gl) for raster + vector serving
- **nginx** — use an nginx module or lightweight proxy to read tiles from SQLite directly
