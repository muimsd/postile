# Tippecanoe Settings

Each source can include a `[sources.tippecanoe]` section to fine-tune how Tippecanoe generates tiles. All settings are optional.

```toml
[[sources]]
name = "basemap"
mbtiles_path = "./basemap.mbtiles"
min_zoom = 0
max_zoom = 14

[sources.tippecanoe]
drop_densest_as_needed = true
no_tile_size_limit = true
no_feature_limit = true
buffer = 5
full_detail = 12
extra_args = ["--cluster-distance=10"]
```

## Settings Reference

| Setting | Tippecanoe flag | Description |
|---------|----------------|-------------|
| `drop_densest_as_needed` | `--drop-densest-as-needed` | Drop features in the densest areas to stay under tile size limits |
| `drop_fraction_as_needed` | `--drop-fraction-as-needed` | Drop a fraction of features at random |
| `drop_smallest_as_needed` | `--drop-smallest-as-needed` | Drop the smallest features first |
| `coalesce_densest_as_needed` | `--coalesce-densest-as-needed` | Merge nearby features in dense areas |
| `extend_zooms_if_still_dropping` | `--extend-zooms-if-still-dropping` | Continue to higher zooms if features are still being dropped |
| `drop_rate` | `--drop-rate` | Rate at which features are dropped at lower zooms (default: 2.5) |
| `base_zoom` | `--base-zoom` | Base zoom level for drop rate calculation |
| `simplification` | `--simplification` | Simplification factor in tile coordinate units |
| `detect_shared_borders` | `--detect-shared-borders` | Detect and simplify shared polygon borders identically |
| `no_tiny_polygon_reduction` | `--no-tiny-polygon-reduction` | Don't collapse very small polygons into single pixels |
| `no_feature_limit` | `--no-feature-limit` | Remove the default 200,000 feature-per-tile limit |
| `no_tile_size_limit` | `--no-tile-size-limit` | Remove the default 500KB tile size limit (default: true) |
| `no_tile_compression` | `--no-tile-compression` | Don't gzip-compress PBF tile data |
| `buffer` | `--buffer` | Pixel buffer around each tile edge |
| `full_detail` | `--full-detail` | Detail level at max zoom (2^n coordinate units) |
| `low_detail` | `--low-detail` | Detail level at lower zoom levels |
| `minimum_detail` | `--minimum-detail` | Minimum detail level below which features are dropped |
| `extra_args` | *(any)* | Array of additional raw Tippecanoe arguments |

The `extra_args` field is an escape hatch for any Tippecanoe option not explicitly modeled. Each array element is passed as a separate argument.
