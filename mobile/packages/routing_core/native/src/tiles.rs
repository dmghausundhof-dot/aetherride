//! Detect Valhalla tile extracts and AetherRide offline graph packs.

use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TileBundle {
    /// `offline_graph.json` (interim offline engine until libvalhalla is linked)
    OfflineGraph(PathBuf),
    /// Valhalla config + tiles (needs `feature = "valhalla"`)
    ValhallaExtract { root: PathBuf, config: PathBuf },
}

pub fn resolve_bundle(path: &Path) -> Option<TileBundle> {
    if !path.exists() {
        return None;
    }
    if path.is_file() {
        let name = path.file_name()?.to_str()?;
        if name == "offline_graph.json" || name.ends_with(".offline_graph.json") {
            return Some(TileBundle::OfflineGraph(path.to_path_buf()));
        }
        if name == "valhalla.json" {
            return Some(TileBundle::ValhallaExtract {
                root: path.parent()?.to_path_buf(),
                config: path.to_path_buf(),
            });
        }
        return None;
    }

    let graph = path.join("offline_graph.json");
    if graph.is_file() {
        return Some(TileBundle::OfflineGraph(graph));
    }

    let config = path.join("valhalla.json");
    if config.is_file() {
        return Some(TileBundle::ValhallaExtract {
            root: path.to_path_buf(),
            config,
        });
    }

    // Valhalla tile tree often lives under tiles/ without config in the same folder
    let tiles_dir = path.join("tiles");
    if tiles_dir.is_dir() {
        return Some(TileBundle::ValhallaExtract {
            root: path.to_path_buf(),
            config: config,
        });
    }

    None
}

pub fn tiles_readable(path: &Path) -> bool {
    resolve_bundle(path).is_some()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;

    #[test]
    fn detects_offline_graph_file() {
        let dir = std::env::temp_dir().join("ar_tiles_test_graph");
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).unwrap();
        let g = dir.join("offline_graph.json");
        fs::write(&g, "{}").unwrap();
        assert!(matches!(
            resolve_bundle(&dir),
            Some(TileBundle::OfflineGraph(_))
        ));
        let _ = fs::remove_dir_all(&dir);
    }
}
