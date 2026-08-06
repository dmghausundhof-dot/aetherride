//! AetherRide dsp_core — complementary filter fusion + impact/flow metrics.
//! Desktop-testable; shared iOS/Android via FFI.

use std::os::raw::{c_double, c_int};

const G: f64 = 9.81;

#[repr(C)]
pub struct RawSample {
    pub t_ms: i64,
    pub ax: f64,
    pub ay: f64,
    pub az: f64,
    pub gx: f64,
    pub gy: f64,
    pub gz: f64,
}

#[repr(C)]
pub struct FusedOut {
    pub timestamp_ms: i64,
    pub g_force_peak: f64,
    pub g_force_rms: f64,
    pub lean_angle_deg: f64,
    pub impact_detected: c_int,
    pub impact_magnitude: f64,
    pub flow_contribution: f64,
}

/// Process a 1-s block of samples into fused metrics.
/// Returns 1 on success, 0 if too few samples.
#[no_mangle]
pub unsafe extern "C" fn dsp_fuse_block(
    samples: *const RawSample,
    len: usize,
    impact_threshold_g: c_double,
    lean_alpha: c_double,
    out: *mut FusedOut,
) -> c_int {
    if samples.is_null() || out.is_null() || len < 5 {
        return 0;
    }
    let slice = std::slice::from_raw_parts(samples, len);
    let mut g_forces: Vec<f64> = Vec::with_capacity(len);
    for s in slice {
        let mag = (s.ax * s.ax + s.ay * s.ay + s.az * s.az).sqrt() / G;
        g_forces.push(mag);
    }
    let g_peak = g_forces.iter().cloned().fold(0.0_f64, f64::max);
    let mean = g_forces.iter().sum::<f64>() / g_forces.len() as f64;
    let var = g_forces.iter().map(|g| (g - mean).powi(2)).sum::<f64>() / g_forces.len() as f64;
    let g_rms = var.sqrt();

    let latest = &slice[len - 1];
    // Complementary lean from accel roll + gyro
    let accel_lean = (latest.ay).atan2(latest.az).to_degrees();
    static mut LAST_LEAN: f64 = 0.0;
    let alpha = if lean_alpha > 0.0 && lean_alpha < 1.0 {
        lean_alpha
    } else {
        0.15
    };
    let lean = alpha * accel_lean + (1.0 - alpha) * LAST_LEAN;
    LAST_LEAN = lean;

    let impact = if g_peak >= impact_threshold_g { 1 } else { 0 };
    // Flow: inverse of high-frequency jerkiness (simple smoothness)
    let flow = (1.0 / (1.0 + g_rms * 2.0)).clamp(0.0, 1.0);

    *out = FusedOut {
        timestamp_ms: latest.t_ms,
        g_force_peak: g_peak,
        g_force_rms: g_rms,
        lean_angle_deg: lean,
        impact_detected: impact,
        impact_magnitude: if impact == 1 { g_peak } else { 0.0 },
        flow_contribution: flow,
    };
    1
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fuse_detects_impact() {
        let mut samples = Vec::new();
        for i in 0..20 {
            samples.push(RawSample {
                t_ms: i * 10,
                ax: 0.0,
                ay: 0.0,
                az: G,
                gx: 0.0,
                gy: 0.0,
                gz: 0.0,
            });
        }
        samples[10].az = G * 5.0;
        let mut out = FusedOut {
            timestamp_ms: 0,
            g_force_peak: 0.0,
            g_force_rms: 0.0,
            lean_angle_deg: 0.0,
            impact_detected: 0,
            impact_magnitude: 0.0,
            flow_contribution: 0.0,
        };
        let ok = unsafe { dsp_fuse_block(samples.as_ptr(), samples.len(), 2.8, 0.15, &mut out) };
        assert_eq!(ok, 1);
        assert!(out.g_force_peak > 2.8);
        assert_eq!(out.impact_detected, 1);
    }
}
