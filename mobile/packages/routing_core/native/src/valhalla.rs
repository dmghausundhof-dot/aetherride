//! Valhalla C API bridge (+ polyline decode for route responses).

use crate::graph::RoutePath;
use crate::profiles::{valhalla_route_body, Profile};
use std::path::Path;

/// Returns the Valhalla request JSON string (parity with server HTTP client).
pub fn build_request_json(
    profile: Profile,
    from_lat: f64,
    from_lng: f64,
    to_lat: f64,
    to_lng: f64,
) -> String {
    valhalla_route_body(profile, from_lat, from_lng, to_lat, to_lng).to_string()
}

/// Decode Valhalla precision-6 polyline → (lng, lat) pairs.
pub fn decode_polyline6(encoded: &str) -> Vec<(f64, f64)> {
    let bytes = encoded.as_bytes();
    let mut index = 0usize;
    let mut lat: i64 = 0;
    let mut lng: i64 = 0;
    let mut coordinates = Vec::new();
    while index < bytes.len() {
        let mut b: i64;
        let mut shift = 0;
        let mut result: i64 = 0;
        loop {
            b = bytes[index] as i64 - 63;
            index += 1;
            result |= (b & 0x1f) << shift;
            shift += 5;
            if b < 0x20 {
                break;
            }
        }
        let dlat = if (result & 1) != 0 {
            !(result >> 1)
        } else {
            result >> 1
        };
        lat += dlat;
        shift = 0;
        result = 0;
        loop {
            b = bytes[index] as i64 - 63;
            index += 1;
            result |= (b & 0x1f) << shift;
            shift += 5;
            if b < 0x20 {
                break;
            }
        }
        let dlng = if (result & 1) != 0 {
            !(result >> 1)
        } else {
            result >> 1
        };
        lng += dlng;
        coordinates.push((lng as f64 / 1e6, lat as f64 / 1e6));
    }
    coordinates
}

#[cfg_attr(not(feature = "valhalla"), allow(dead_code))]
fn parse_valhalla_route_json(body: &str) -> Result<RoutePath, String> {
    let v: serde_json::Value =
        serde_json::from_str(body).map_err(|e| format!("valhalla json: {e}"))?;
    let trip = v
        .get("trip")
        .ok_or_else(|| "valhalla: missing trip".to_string())?;
    let shape = trip
        .pointer("/legs/0/shape")
        .or_else(|| trip.get("shape"))
        .and_then(|s| s.as_str())
        .ok_or_else(|| "valhalla: missing shape".to_string())?;
    let coordinates = decode_polyline6(shape);
    if coordinates.len() < 2 {
        return Err("valhalla: empty geometry".into());
    }
    let distance_m = trip
        .pointer("/summary/length")
        .and_then(|x| x.as_f64())
        .unwrap_or(0.0)
        * 1000.0;
    let duration_s = trip
        .pointer("/summary/time")
        .and_then(|x| x.as_f64())
        .unwrap_or(0.0);
    Ok(RoutePath {
        distance_m,
        duration_s,
        coordinates,
    })
}

#[cfg(feature = "valhalla")]
mod linked {
    use super::*;
    use std::ffi::{CStr, CString};
    use std::os::raw::c_char;

    extern "C" {
        fn valhalla_actor_create(config_path: *const c_char) -> *mut std::ffi::c_void;
        fn valhalla_actor_destroy(actor: *mut std::ffi::c_void);
        fn valhalla_actor_route(
            actor: *mut std::ffi::c_void,
            request_json: *const c_char,
        ) -> *mut c_char;
        fn valhalla_string_free(s: *mut c_char);
        fn valhalla_last_error() -> *const c_char;
        fn valhalla_is_linked() -> i32;
    }

    fn last_error() -> String {
        unsafe {
            let p = valhalla_last_error();
            if p.is_null() {
                return "unknown valhalla error".into();
            }
            CStr::from_ptr(p).to_string_lossy().into_owned()
        }
    }

    pub fn route_with_valhalla(
        config: &Path,
        profile: Profile,
        from_lat: f64,
        from_lng: f64,
        to_lat: f64,
        to_lng: f64,
    ) -> Result<RoutePath, String> {
        let cfg = CString::new(config.to_string_lossy().as_bytes())
            .map_err(|_| "config path nul".to_string())?;
        let actor = unsafe { valhalla_actor_create(cfg.as_ptr()) };
        if actor.is_null() {
            return Err(format!("valhalla_actor_create: {}", last_error()));
        }
        let req = build_request_json(profile, from_lat, from_lng, to_lat, to_lng);
        let req_c = CString::new(req).map_err(|_| "request nul".to_string())?;
        let raw = unsafe { valhalla_actor_route(actor, req_c.as_ptr()) };
        unsafe { valhalla_actor_destroy(actor) };
        if raw.is_null() {
            return Err(format!("valhalla_actor_route: {}", last_error()));
        }
        let json = unsafe {
            let s = CStr::from_ptr(raw).to_string_lossy().into_owned();
            valhalla_string_free(raw);
            s
        };
        if unsafe { valhalla_is_linked() } == 0 {
            return Err(json); // stub message
        }
        parse_valhalla_route_json(&json)
    }
}

#[cfg(feature = "valhalla")]
pub use linked::route_with_valhalla;

#[cfg(not(feature = "valhalla"))]
pub fn route_with_valhalla(
    _config: &Path,
    _profile: Profile,
    _from_lat: f64,
    _from_lng: f64,
    _to_lat: f64,
    _to_lng: f64,
) -> Result<RoutePath, String> {
    Err(
        "valhalla feature not enabled — rebuild with --features valhalla after linking libvalhalla"
            .into(),
    )
}

/// 1 if real libvalhalla is linked into this binary, else 0.
pub fn is_linked() -> i32 {
    #[cfg(feature = "valhalla")]
    {
        extern "C" {
            fn valhalla_is_linked() -> i32;
        }
        // Avoid name collision with the C symbol on the public API — callers use
        // `routing_core_valhalla_is_linked` (see lib.rs).
        unsafe { valhalla_is_linked() }
    }
    #[cfg(not(feature = "valhalla"))]
    {
        0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn polyline_roundtrip_smoke() {
        // trivial single-point-ish encoded empty → empty
        assert!(decode_polyline6("").is_empty());
    }
}
