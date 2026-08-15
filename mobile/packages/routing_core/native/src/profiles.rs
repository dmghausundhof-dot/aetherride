//! Spec F-NAV-001 — eight profiles + Valhalla costing mirrored from
//! `src/lib/routing/profiles.ts` (keep in sync with valhalla-costing.json).

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Profile {
    MtbAllmountain,
    MtbEnduro,
    Gravel,
    Road,
    Ebike,
    Emtb,
    Downhill,
    Hiking,
}

impl Profile {
    pub fn parse(id: &str) -> Option<Self> {
        match id {
            "mtb_allmountain" => Some(Self::MtbAllmountain),
            "mtb_enduro" => Some(Self::MtbEnduro),
            "gravel" => Some(Self::Gravel),
            "road" => Some(Self::Road),
            "ebike" => Some(Self::Ebike),
            "emtb" => Some(Self::Emtb),
            "downhill" | "dh" => Some(Self::Downhill),
            "hiking" => Some(Self::Hiking),
            _ => None,
        }
    }

    #[allow(dead_code)]
    pub fn as_str(self) -> &'static str {
        match self {
            Self::MtbAllmountain => "mtb_allmountain",
            Self::MtbEnduro => "mtb_enduro",
            Self::Gravel => "gravel",
            Self::Road => "road",
            Self::Ebike => "ebike",
            Self::Emtb => "emtb",
            Self::Downhill => "downhill",
            Self::Hiking => "hiking",
        }
    }

    /// Nominal speed m/s for duration estimates (offline graph / geodesic).
    pub fn speed_mps(self) -> f64 {
        match self {
            Self::Hiking => 1.2,
            Self::Road => 7.0,
            Self::Gravel => 5.0,
            Self::Ebike => 6.0,
            Self::Emtb => 4.5,
            Self::MtbAllmountain => 3.5,
            Self::MtbEnduro => 3.0,
            Self::Downhill => 3.2,
        }
    }

    /// Valhalla costing name + options — identical to `buildValhallaCosting`.
    pub fn valhalla_costing_json(self) -> serde_json::Value {
        match self {
            Self::Hiking => serde_json::json!({
                "costing": "pedestrian",
                "costing_options": { "pedestrian": { "walking_speed": 4.5, "use_hills": 0.6 } }
            }),
            Self::Road => serde_json::json!({
                "costing": "bicycle",
                "costing_options": { "bicycle": {
                    "bicycle_type": "road", "use_roads": 0.9, "use_hills": 0.2, "avoid_bad_surfaces": 0.8
                }}
            }),
            Self::Gravel => serde_json::json!({
                "costing": "bicycle",
                "costing_options": { "bicycle": {
                    "bicycle_type": "hybrid", "use_roads": 0.4, "use_hills": 0.4, "avoid_bad_surfaces": 0.3
                }}
            }),
            Self::Ebike => serde_json::json!({
                "costing": "bicycle",
                "costing_options": { "bicycle": {
                    "bicycle_type": "hybrid", "use_roads": 0.5, "use_hills": 0.85, "avoid_bad_surfaces": 0.4
                }}
            }),
            Self::Emtb => serde_json::json!({
                "costing": "bicycle",
                "costing_options": { "bicycle": {
                    "bicycle_type": "mountain", "use_roads": 0.2, "use_hills": 0.95, "avoid_bad_surfaces": 0.1
                }}
            }),
            Self::MtbEnduro => serde_json::json!({
                "costing": "bicycle",
                "costing_options": { "bicycle": {
                    "bicycle_type": "mountain", "use_roads": 0.1, "use_hills": 0.9, "avoid_bad_surfaces": 0.05
                }}
            }),
            Self::Downhill => serde_json::json!({
                "costing": "bicycle",
                "costing_options": { "bicycle": {
                    "bicycle_type": "mountain", "use_roads": 0.05, "use_hills": 1.0, "avoid_bad_surfaces": 0.0
                }}
            }),
            Self::MtbAllmountain => serde_json::json!({
                "costing": "bicycle",
                "costing_options": { "bicycle": {
                    "bicycle_type": "mountain", "use_roads": 0.25, "use_hills": 0.75, "avoid_bad_surfaces": 0.15
                }}
            }),
        }
    }

    /// Edge cost multiplier: lower = preferred for this profile.
    pub fn edge_factor(self, highway: &str, mtb_scale: Option<u8>, surface: &str) -> Option<f64> {
        let rough = matches!(
            surface,
            "ground" | "dirt" | "mud" | "gravel" | "fine_gravel" | "compacted" | ""
        );
        let paved = matches!(surface, "asphalt" | "paved" | "concrete");

        match self {
            Self::Road => {
                if matches!(highway, "path" | "track" | "footway" | "steps") {
                    return None;
                }
                if !paved && rough {
                    return Some(4.0);
                }
                Some(1.0)
            }
            Self::Gravel => {
                if matches!(highway, "motorway" | "trunk" | "steps") {
                    return None;
                }
                if mtb_scale.unwrap_or(0) >= 4 {
                    return None;
                }
                if matches!(surface, "gravel" | "compacted" | "fine_gravel") || highway == "track" {
                    Some(0.8)
                } else if paved {
                    Some(1.2)
                } else {
                    Some(1.0)
                }
            }
            Self::Hiking => {
                if matches!(highway, "motorway" | "trunk" | "primary") {
                    return None;
                }
                if matches!(highway, "path" | "footway" | "track") {
                    Some(0.85)
                } else {
                    Some(1.3)
                }
            }
            Self::MtbEnduro => {
                if matches!(highway, "motorway" | "trunk" | "primary" | "steps") {
                    return None;
                }
                let s = mtb_scale.unwrap_or(1);
                if s >= 2 {
                    Some(0.7)
                } else if highway == "path" || highway == "track" {
                    Some(0.9)
                } else {
                    Some(1.4)
                }
            }
            Self::Downhill => {
                if matches!(highway, "motorway" | "trunk" | "primary" | "secondary" | "steps") {
                    return None;
                }
                let s = mtb_scale.unwrap_or(0);
                if s >= 3 {
                    Some(0.55)
                } else if s >= 1 {
                    Some(0.7)
                } else if highway == "path" || highway == "track" {
                    Some(1.15)
                } else {
                    Some(2.2)
                }
            }
            Self::MtbAllmountain | Self::Emtb => {
                if matches!(highway, "motorway" | "trunk" | "steps") {
                    return None;
                }
                let max = if self == Self::Emtb { 4 } else { 3 };
                if mtb_scale.unwrap_or(0) > max {
                    return Some(2.5);
                }
                if matches!(highway, "path" | "track" | "cycleway") {
                    Some(0.85)
                } else {
                    Some(1.2)
                }
            }
            Self::Ebike => {
                if matches!(highway, "motorway" | "steps") {
                    return None;
                }
                if mtb_scale.unwrap_or(0) >= 4 {
                    return None;
                }
                if matches!(highway, "cycleway" | "track" | "path" | "tertiary") {
                    Some(0.9)
                } else {
                    Some(1.15)
                }
            }
        }
    }
}

/// Build Valhalla `/route` POST body (same shape as server).
pub fn valhalla_route_body(
    profile: Profile,
    from_lat: f64,
    from_lng: f64,
    to_lat: f64,
    to_lng: f64,
) -> serde_json::Value {
    let costing = profile.valhalla_costing_json();
    serde_json::json!({
        "locations": [
            { "lon": from_lng, "lat": from_lat },
            { "lon": to_lng, "lat": to_lat }
        ],
        "costing": costing["costing"],
        "costing_options": costing["costing_options"],
        "directions_options": { "units": "kilometers" }
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn all_eight_parse() {
        for id in [
            "mtb_allmountain",
            "mtb_enduro",
            "gravel",
            "road",
            "ebike",
            "emtb",
            "downhill",
            "hiking",
        ] {
            assert!(Profile::parse(id).is_some());
        }
        assert_eq!(Profile::parse("dh"), Some(Profile::Downhill));
    }

    #[test]
    fn costing_has_bicycle_or_pedestrian() {
        let j = Profile::MtbEnduro.valhalla_costing_json();
        assert_eq!(j["costing"], "bicycle");
        let h = Profile::Hiking.valhalla_costing_json();
        assert_eq!(h["costing"], "pedestrian");
        let d = Profile::Downhill.valhalla_costing_json();
        assert_eq!(d["costing"], "bicycle");
        assert_eq!(d["costing_options"]["bicycle"]["use_hills"], 1.0);
        assert_eq!(d["costing_options"]["bicycle"]["use_roads"], 0.05);
    }

    #[test]
    fn downhill_prefers_technical_trails() {
        let p = Profile::Downhill;
        assert!(p.edge_factor("motorway", None, "asphalt").is_none());
        assert_eq!(p.edge_factor("path", Some(2), "dirt"), Some(0.7));
        assert_eq!(p.edge_factor("path", Some(3), "dirt"), Some(0.55));
    }
}
