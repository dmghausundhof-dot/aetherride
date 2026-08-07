//! Valhalla offline FFI (Spec §5.1 `routing_core`, §5.4).
//!
//! Engines:
//! 1. `offline_graph.json` pack — A* (works today, same Spec-7 profiles)
//! 2. Valhalla tile extract — requires `--features valhalla` + libvalhalla link
//!
//! Costing JSON matches server `src/lib/routing/engine.ts`.

mod graph;
mod profiles;
mod tiles;
mod valhalla;

use graph::load_graph;
use profiles::Profile;
use std::os::raw::{c_char, c_double, c_int};
use std::path::Path;
use tiles::{resolve_bundle, tiles_readable, TileBundle};

/// Result codes
pub const ROUTING_OK: c_int = 0;
/// Valhalla tiles present but libvalhalla not linked / bridge unavailable
pub const ROUTING_VALHALLA_UNLINKED: c_int = 1;
pub const ROUTING_INVALID_ARGS: c_int = 2;
pub const ROUTING_NO_TILES: c_int = 3;
pub const ROUTING_NO_ROUTE: c_int = 4;
pub const ROUTING_BUFFER_TOO_SMALL: c_int = 5;
pub const ROUTING_UNKNOWN_PROFILE: c_int = 6;

/// Deprecated alias — kept for Dart bindings that still check code `1`.
pub const ROUTING_NOT_IMPLEMENTED: c_int = ROUTING_VALHALLA_UNLINKED;

#[repr(C)]
pub struct RouteRequest {
    pub from_lat: c_double,
    pub from_lng: c_double,
    pub to_lat: c_double,
    pub to_lng: c_double,
    /// NUL-terminated profile id, e.g. "mtb_enduro"
    pub profile: *const c_char,
    /// Path to tile root or offline_graph.json (NUL-terminated)
    pub tiles_path: *const c_char,
}

#[repr(C)]
pub struct RouteSummary {
    pub distance_m: c_double,
    pub duration_s: c_double,
    pub coordinate_count: u32,
}

fn cstr<'a>(p: *const c_char) -> Option<&'a str> {
    if p.is_null() {
        return None;
    }
    unsafe { std::ffi::CStr::from_ptr(p) }.to_str().ok()
}

fn valid_lat_lng(lat: f64, lng: f64) -> bool {
    lat.is_finite() && lng.is_finite() && (-90.0..=90.0).contains(&lat) && (-180.0..=180.0).contains(&lng)
}

fn write_coords(path: &[(f64, f64)], out: *mut c_double, cap: u32) -> Result<u32, c_int> {
    let need = path.len() as u32;
    if out.is_null() || need > cap {
        return Err(ROUTING_BUFFER_TOO_SMALL);
    }
    unsafe {
        for (i, &(lng, lat)) in path.iter().enumerate() {
            *out.add(i * 2) = lng;
            *out.add(i * 2 + 1) = lat;
        }
    }
    Ok(need)
}

/// Dynsym-visible link probe for Dart FFI (`DynamicLibrary.lookup`).
/// Prefer this over looking up the C shim `valhalla_is_linked` directly.
#[no_mangle]
pub unsafe extern "C" fn routing_core_valhalla_is_linked() -> c_int {
    valhalla::is_linked()
}

/// Offline route. Prefer Valhalla extract when present; else offline_graph.
#[no_mangle]
pub unsafe extern "C" fn routing_core_route(
    req: *const RouteRequest,
    out: *mut RouteSummary,
    coords_lng_lat: *mut c_double,
    coords_cap: u32,
) -> c_int {
    if req.is_null() || out.is_null() {
        return ROUTING_INVALID_ARGS;
    }
    let r = &*req;
    if !valid_lat_lng(r.from_lat, r.from_lng) || !valid_lat_lng(r.to_lat, r.to_lng) {
        return ROUTING_INVALID_ARGS;
    }
    let Some(profile_s) = cstr(r.profile) else {
        return ROUTING_INVALID_ARGS;
    };
    let Some(profile) = Profile::parse(profile_s) else {
        return ROUTING_UNKNOWN_PROFILE;
    };
    let Some(tiles_s) = cstr(r.tiles_path) else {
        return ROUTING_INVALID_ARGS;
    };
    let tiles_path = Path::new(tiles_s);
    let Some(bundle) = resolve_bundle(tiles_path) else {
        return ROUTING_NO_TILES;
    };

    let routed = match bundle {
        TileBundle::OfflineGraph(graph_path) => {
            let g = match load_graph(&graph_path) {
                Ok(g) => g,
                Err(_) => return ROUTING_NO_TILES,
            };
            graph::route(
                &g,
                profile,
                r.from_lat,
                r.from_lng,
                r.to_lat,
                r.to_lng,
            )
        }
        TileBundle::ValhallaExtract { config, .. } => {
            match valhalla::route_with_valhalla(
                &config,
                profile,
                r.from_lat,
                r.from_lng,
                r.to_lat,
                r.to_lng,
            ) {
                Ok(p) => Some(p),
                Err(_) => return ROUTING_VALHALLA_UNLINKED,
            }
        }
    };

    let Some(path) = routed else {
        return ROUTING_NO_ROUTE;
    };

    let count = match write_coords(&path.coordinates, coords_lng_lat, coords_cap) {
        Ok(c) => c,
        Err(code) => {
            // Still fill summary so caller can reallocate
            (*out).distance_m = path.distance_m;
            (*out).duration_s = path.duration_s;
            (*out).coordinate_count = path.coordinates.len() as u32;
            return code;
        }
    };

    (*out).distance_m = path.distance_m;
    (*out).duration_s = path.duration_s;
    (*out).coordinate_count = count;
    ROUTING_OK
}

/// Returns 1 if a Valhalla extract or offline_graph pack is readable at path.
#[no_mangle]
pub unsafe extern "C" fn routing_core_tiles_ok(path: *const c_char) -> c_int {
    let Some(p) = cstr(path) else {
        return 0;
    };
    if tiles_readable(Path::new(p)) {
        1
    } else {
        0
    }
}

/// Engine id for diagnostics: "offline_graph" | "valhalla" | "none"
#[no_mangle]
pub unsafe extern "C" fn routing_core_engine_for_tiles(path: *const c_char) -> *const c_char {
    static OFFLINE: &[u8] = b"offline_graph\0";
    static VALHALLA: &[u8] = b"valhalla\0";
    static NONE: &[u8] = b"none\0";
    let Some(p) = cstr(path) else {
        return NONE.as_ptr() as *const c_char;
    };
    match resolve_bundle(Path::new(p)) {
        Some(TileBundle::OfflineGraph(_)) => OFFLINE.as_ptr() as *const c_char,
        Some(TileBundle::ValhallaExtract { .. }) => VALHALLA.as_ptr() as *const c_char,
        None => NONE.as_ptr() as *const c_char,
    }
}

/// NUL-terminated Valhalla request JSON for host tooling (malloc'd — free with routing_core_string_free).
#[no_mangle]
pub unsafe extern "C" fn routing_core_valhalla_request_json(
    profile: *const c_char,
    from_lat: c_double,
    from_lng: c_double,
    to_lat: c_double,
    to_lng: c_double,
) -> *mut c_char {
    let Some(profile_s) = cstr(profile) else {
        return std::ptr::null_mut();
    };
    let Some(p) = Profile::parse(profile_s) else {
        return std::ptr::null_mut();
    };
    if !valid_lat_lng(from_lat, from_lng) || !valid_lat_lng(to_lat, to_lng) {
        return std::ptr::null_mut();
    }
    let s = valhalla::build_request_json(p, from_lat, from_lng, to_lat, to_lng);
    match std::ffi::CString::new(s) {
        Ok(c) => c.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub unsafe extern "C" fn routing_core_string_free(s: *mut c_char) {
    if s.is_null() {
        return;
    }
    drop(std::ffi::CString::from_raw(s));
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;
    use std::path::PathBuf;

    fn sample_graph() -> PathBuf {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("testdata/offline_graph.json")
    }

    #[test]
    fn offline_graph_route_ok() {
        let profile = CString::new("mtb_enduro").unwrap();
        let tiles = CString::new(sample_graph().to_str().unwrap()).unwrap();
        let req = RouteRequest {
            from_lat: 47.99,
            from_lng: 7.85,
            to_lat: 47.95,
            to_lng: 7.92,
            profile: profile.as_ptr(),
            tiles_path: tiles.as_ptr(),
        };
        let mut out = RouteSummary {
            distance_m: 0.0,
            duration_s: 0.0,
            coordinate_count: 0,
        };
        let mut buf = vec![0.0_f64; 64];
        let code = unsafe {
            routing_core_route(&req, &mut out, buf.as_mut_ptr(), (buf.len() / 2) as u32)
        };
        assert_eq!(code, ROUTING_OK, "expected OK got {code}");
        assert!(out.distance_m > 1000.0);
        assert!(out.coordinate_count >= 3);
    }

    #[test]
    fn probe_null_buffer_reports_size() {
        let profile = CString::new("mtb_enduro").unwrap();
        let tiles = CString::new(sample_graph().to_str().unwrap()).unwrap();
        let req = RouteRequest {
            from_lat: 47.99,
            from_lng: 7.85,
            to_lat: 47.95,
            to_lng: 7.92,
            profile: profile.as_ptr(),
            tiles_path: tiles.as_ptr(),
        };
        let mut out = RouteSummary {
            distance_m: 0.0,
            duration_s: 0.0,
            coordinate_count: 0,
        };
        let code = unsafe { routing_core_route(&req, &mut out, std::ptr::null_mut(), 0) };
        assert_eq!(code, ROUTING_BUFFER_TOO_SMALL);
        assert!(out.coordinate_count >= 3);
    }

    #[test]
    fn missing_tiles_returns_no_tiles() {
        let profile = CString::new("mtb_enduro").unwrap();
        let tiles = CString::new("/tmp/ar-no-such-tiles-xyz").unwrap();
        let req = RouteRequest {
            from_lat: 47.99,
            from_lng: 7.85,
            to_lat: 47.95,
            to_lng: 7.92,
            profile: profile.as_ptr(),
            tiles_path: tiles.as_ptr(),
        };
        let mut out = RouteSummary {
            distance_m: 0.0,
            duration_s: 0.0,
            coordinate_count: 0,
        };
        let code = unsafe { routing_core_route(&req, &mut out, std::ptr::null_mut(), 0) };
        assert_eq!(code, ROUTING_NO_TILES);
    }

    #[test]
    fn unknown_profile() {
        let profile = CString::new("skateboard").unwrap();
        let tiles = CString::new(sample_graph().to_str().unwrap()).unwrap();
        let req = RouteRequest {
            from_lat: 47.99,
            from_lng: 7.85,
            to_lat: 47.95,
            to_lng: 7.92,
            profile: profile.as_ptr(),
            tiles_path: tiles.as_ptr(),
        };
        let mut out = RouteSummary {
            distance_m: 0.0,
            duration_s: 0.0,
            coordinate_count: 0,
        };
        let code = unsafe { routing_core_route(&req, &mut out, std::ptr::null_mut(), 0) };
        assert_eq!(code, ROUTING_UNKNOWN_PROFILE);
    }
}
