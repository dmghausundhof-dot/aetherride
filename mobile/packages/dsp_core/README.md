# dsp_core

Rust signal processing (Spec §5.5) + Dart FFI with pure-Dart fallback.

```bash
cd native && cargo test && cargo build --release
# Link libdsp_core into Android/iOS via CMake / Xcode (see README in mobile/)
```

C ABI: `dsp_fuse_block(samples, len, impact_threshold_g, lean_alpha, out) -> int`
