use std::env;
use std::path::PathBuf;

fn main() {
    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let cpp = manifest.join("cpp/valhalla_actor_c.cpp");

    // Always compile the C shim (stub unless AETHER_VALHALLA_LINKED).
    // Feature `valhalla` enables Rust FFI calls into the shim.
    if env::var("CARGO_FEATURE_VALHALLA").is_ok() {
        let mut build = cc::Build::new();
        build.cpp(true).file(&cpp).include(manifest.join("cpp"));
        build.flag_if_supported("-std=c++17");
        build.flag_if_supported("-Wno-unused-parameter");

        if let Ok(inc) = env::var("VALHALLA_INCLUDE_DIR") {
            build.include(&inc);
            build.define("AETHER_VALHALLA_LINKED", None);
            println!("cargo:warning=linking Valhalla headers from {inc}");
        }

        if let Ok(lib) = env::var("VALHALLA_LIB_DIR") {
            println!("cargo:rustc-link-search=native={lib}");
            // Prefer shared on Android NDK, static on iOS — override via VALHALLA_LINK_LIB
            let link_lib = env::var("VALHALLA_LINK_LIB").unwrap_or_else(|_| "valhalla".into());
            let kind = env::var("VALHALLA_LINK_KIND").unwrap_or_else(|_| "dylib".into());
            println!("cargo:rustc-link-lib={kind}={link_lib}");
            // Common transitive deps when statically linking
            if kind == "static" {
                for dep in ["protobuf", "z", "curl", "sqlite3"] {
                    println!("cargo:rustc-link-lib={dep}");
                }
                println!("cargo:rustc-link-lib=stdc++");
            }
        } else {
            println!(
                "cargo:warning=VALHALLA_LIB_DIR unset — building stub actor (valhalla_is_linked=0)"
            );
        }

        build.compile("valhalla_actor_c");
        println!("cargo:rerun-if-changed=cpp/valhalla_actor_c.cpp");
        println!("cargo:rerun-if-changed=cpp/valhalla_actor_c.h");
        println!("cargo:rerun-if-env-changed=VALHALLA_INCLUDE_DIR");
        println!("cargo:rerun-if-env-changed=VALHALLA_LIB_DIR");
    }
}
