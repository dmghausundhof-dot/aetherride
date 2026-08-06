//! Valhalla offline FFI scaffold (S7).
//! Full NDK/C++ embed is a separate epic — this crate exposes the C ABI
//! contract and a stub that returns NOT_IMPLEMENTED until linked against
//! libvalhalla.

use std::os::raw::{c_char, c_double, c_int};

/// Result codes
pub const ROUTING_OK: c_int = 0;
pub const ROUTING_NOT_IMPLEMENTED: c_int = 1;
pub const ROUTING_INVALID_ARGS: c_int = 2;
pub const ROUTING_NO_TILES: c_int = 3;

#[repr(C)]
pub struct RouteRequest {
    pub from_lat: c_double,
    pub from_lng: c_double,
    pub to_lat: c_double,
    pub to_lng: c_double,
    /// NUL-terminated profile id, e.g. "mtb_enduro"
    pub profile: *const c_char,
    /// Path to Valhalla tile extract (NUL-terminated)
    pub tiles_path: *const c_char,
}

#[repr(C)]
pub struct RouteSummary {
    pub distance_m: c_double,
    pub duration_s: c_double,
    pub coordinate_count: u32,
}

/// Offline route. Currently returns ROUTING_NOT_IMPLEMENTED until
/// linked with Valhalla. Same profiles as server `/api/route`.
#[no_mangle]
pub unsafe extern "C" fn routing_core_route(
    _req: *const RouteRequest,
    _out: *mut RouteSummary,
    _coords_lng_lat: *mut c_double,
    _coords_cap: u32,
) -> c_int {
    ROUTING_NOT_IMPLEMENTED
}

/// Returns 1 if a Valhalla tile set is readable at path.
#[no_mangle]
pub unsafe extern "C" fn routing_core_tiles_ok(path: *const c_char) -> c_int {
    if path.is_null() {
        return 0;
    }
    let cstr = std::ffi::CStr::from_ptr(path);
    let Ok(p) = cstr.to_str() else {
        return 0;
    };
    if std::path::Path::new(p).exists() {
        1
    } else {
        0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn stub_returns_not_implemented() {
        let profile = CString::new("mtb_enduro").unwrap();
        let tiles = CString::new("/tmp/no-tiles").unwrap();
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
        assert_eq!(code, ROUTING_NOT_IMPLEMENTED);
    }
}
