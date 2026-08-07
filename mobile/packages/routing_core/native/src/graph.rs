//! Offline road graph (GeoJSON-adjacent JSON) + A* — Spec interim until Valhalla FFI links.
//!
//! Pack format version 1 — generate from the same OSM extract used for Valhalla tiles
//! so online/offline converge as the graph pack improves.

use crate::profiles::Profile;
use serde::Deserialize;
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
use std::fs;
use std::path::Path;

#[derive(Debug, Deserialize)]
pub struct OfflineGraph {
    pub version: u32,
    pub nodes: Vec<GraphNode>,
    pub edges: Vec<GraphEdge>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct GraphNode {
    pub id: String,
    pub lat: f64,
    pub lng: f64,
}

#[derive(Debug, Deserialize, Clone)]
pub struct GraphEdge {
    pub from: String,
    pub to: String,
    pub length_m: f64,
    #[serde(default = "default_highway")]
    pub highway: String,
    #[serde(default)]
    pub mtb_scale: Option<u8>,
    #[serde(default = "default_surface")]
    pub surface: String,
    /// If true, edge is bidirectional (default true).
    #[serde(default = "default_true")]
    pub bidirectional: bool,
}

fn default_highway() -> String {
    "path".into()
}
fn default_surface() -> String {
    "ground".into()
}
fn default_true() -> bool {
    true
}

#[derive(Debug, Clone)]
pub struct RoutePath {
    pub distance_m: f64,
    pub duration_s: f64,
    /// lng, lat pairs
    pub coordinates: Vec<(f64, f64)>,
}

pub fn load_graph(path: &Path) -> Result<OfflineGraph, String> {
    let raw = fs::read_to_string(path).map_err(|e| e.to_string())?;
    let g: OfflineGraph = serde_json::from_str(&raw).map_err(|e| e.to_string())?;
    if g.version != 1 {
        return Err(format!("unsupported offline_graph version {}", g.version));
    }
    if g.nodes.is_empty() {
        return Err("empty graph".into());
    }
    Ok(g)
}

fn haversine_m(lat1: f64, lng1: f64, lat2: f64, lng2: f64) -> f64 {
    let r = 6_371_000.0_f64;
    let p1 = lat1.to_radians();
    let p2 = lat2.to_radians();
    let dp = (lat2 - lat1).to_radians();
    let dl = (lng2 - lng1).to_radians();
    let a = (dp / 2.0).sin().powi(2) + p1.cos() * p2.cos() * (dl / 2.0).sin().powi(2);
    2.0 * r * a.sqrt().asin()
}

fn nearest_node(g: &OfflineGraph, lat: f64, lng: f64) -> Option<&GraphNode> {
    g.nodes.iter().min_by(|a, b| {
        let da = haversine_m(lat, lng, a.lat, a.lng);
        let db = haversine_m(lat, lng, b.lat, b.lng);
        da.partial_cmp(&db).unwrap_or(Ordering::Equal)
    })
}

#[derive(Copy, Clone, PartialEq)]
struct State {
    cost: f64,
    idx: usize,
}

impl Eq for State {}

impl Ord for State {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .cost
            .partial_cmp(&self.cost)
            .unwrap_or(Ordering::Equal)
            .then_with(|| self.idx.cmp(&other.idx))
    }
}

impl PartialOrd for State {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

pub fn route(g: &OfflineGraph, profile: Profile, from_lat: f64, from_lng: f64, to_lat: f64, to_lng: f64) -> Option<RoutePath> {
    let start = nearest_node(g, from_lat, from_lng)?;
    let goal = nearest_node(g, to_lat, to_lng)?;
    if start.id == goal.id && haversine_m(from_lat, from_lng, to_lat, to_lng) < 25.0 {
        return Some(RoutePath {
            distance_m: haversine_m(from_lat, from_lng, to_lat, to_lng),
            duration_s: haversine_m(from_lat, from_lng, to_lat, to_lng) / profile.speed_mps(),
            coordinates: vec![(from_lng, from_lat), (to_lng, to_lat)],
        });
    }

    let mut id_to_idx: HashMap<&str, usize> = HashMap::new();
    for (i, n) in g.nodes.iter().enumerate() {
        id_to_idx.insert(n.id.as_str(), i);
    }
    let start_i = *id_to_idx.get(start.id.as_str())?;
    let goal_i = *id_to_idx.get(goal.id.as_str())?;

    // adjacency: (to_idx, length_m * factor)
    let mut adj: Vec<Vec<(usize, f64)>> = vec![Vec::new(); g.nodes.len()];
    for e in &g.edges {
        let Some(factor) = profile.edge_factor(&e.highway, e.mtb_scale, &e.surface) else {
            continue;
        };
        let Some(&fi) = id_to_idx.get(e.from.as_str()) else {
            continue;
        };
        let Some(&ti) = id_to_idx.get(e.to.as_str()) else {
            continue;
        };
        let w = e.length_m * factor;
        adj[fi].push((ti, w));
        if e.bidirectional {
            adj[ti].push((fi, w));
        }
    }

    let mut dist = vec![f64::INFINITY; g.nodes.len()];
    let mut prev: Vec<Option<usize>> = vec![None; g.nodes.len()];
    let mut heap = BinaryHeap::new();
    dist[start_i] = 0.0;
    heap.push(State {
        cost: 0.0,
        idx: start_i,
    });

    while let Some(State { cost, idx }) = heap.pop() {
        if cost > dist[idx] {
            continue;
        }
        if idx == goal_i {
            break;
        }
        for &(ni, w) in &adj[idx] {
            let next = cost + w;
            if next < dist[ni] {
                dist[ni] = next;
                prev[ni] = Some(idx);
                heap.push(State { cost: next, idx: ni });
            }
        }
    }

    if !dist[goal_i].is_finite() {
        return None;
    }

    let mut path_idx = Vec::new();
    let mut cur = goal_i;
    path_idx.push(cur);
    while let Some(p) = prev[cur] {
        path_idx.push(p);
        cur = p;
    }
    path_idx.reverse();

    let mut coordinates: Vec<(f64, f64)> = Vec::with_capacity(path_idx.len() + 2);
    coordinates.push((from_lng, from_lat));
    for &i in &path_idx {
        coordinates.push((g.nodes[i].lng, g.nodes[i].lat));
    }
    coordinates.push((to_lng, to_lat));

    // Geometric length along node chain (not weighted cost)
    let mut distance_m = haversine_m(from_lat, from_lng, g.nodes[path_idx[0]].lat, g.nodes[path_idx[0]].lng);
    for w in path_idx.windows(2) {
        distance_m += haversine_m(
            g.nodes[w[0]].lat,
            g.nodes[w[0]].lng,
            g.nodes[w[1]].lat,
            g.nodes[w[1]].lng,
        );
    }
    let last = *path_idx.last()?;
    distance_m += haversine_m(g.nodes[last].lat, g.nodes[last].lng, to_lat, to_lng);

    Some(RoutePath {
        distance_m,
        duration_s: distance_m / profile.speed_mps(),
        coordinates,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn sample_path() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("testdata/offline_graph.json")
    }

    #[test]
    fn routes_black_forest_sample() {
        let g = load_graph(&sample_path()).expect("load");
        let r = route(
            &g,
            Profile::MtbEnduro,
            47.99,
            7.85,
            47.95,
            7.92,
        )
        .expect("route");
        assert!(r.distance_m > 1000.0);
        assert!(r.coordinates.len() >= 3);
    }

    #[test]
    fn routes_osm_derived_asset_graph() {
        // Canonical demo graph: mobile/assets/routing/offline_graph.json (no duplicate in testdata)
        let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("../../../assets/routing/offline_graph.json");
        let g = load_graph(&path).expect("load osm graph");
        let r = route(&g, Profile::MtbEnduro, 47.99, 7.85, 47.95, 7.92).expect("osm route");
        assert!(r.distance_m > 500.0, "dist {}", r.distance_m);
        assert!(r.coordinates.len() >= 3);
    }
}
