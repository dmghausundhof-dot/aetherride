use std::env;
use std::path::PathBuf;

fn main() {
    let target = env::var("TARGET").unwrap_or_default();
    if target.contains("android") {
        // Android 15+ 16 KB pages (Galaxy S25 / Play). ELF LOAD must be 0x4000,
        // not 0x1000 — zip-align alone is not enough.
        println!("cargo:rustc-link-arg=-Wl,-z,max-page-size=16384");
        println!("cargo:rustc-cdylib-link-arg=-Wl,-z,max-page-size=16384");
    }

    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let cpp = manifest.join("cpp/valhalla_actor_c.cpp");

    // Always compile the C shim (stub unless AETHER_VALHALLA_LINKED).
    // Feature `valhalla` enables Rust FFI calls into the shim.
    if env::var("CARGO_FEATURE_VALHALLA").is_ok() {
        let mut build = cc::Build::new();
        build.cpp(true).file(&cpp).include(manifest.join("cpp"));
        build.flag_if_supported("-std=c++17");
        build.flag_if_supported("-Wno-unused-parameter");
        build.flag_if_supported("-fvisibility=default");

        if let Ok(inc) = env::var("VALHALLA_INCLUDE_DIR") {
            build.include(&inc);
            build.include(format!("{inc}/valhalla"));
            build.include(format!("{inc}/valhalla/third_party"));
            build.define("AETHER_VALHALLA_LINKED", None);
            println!("cargo:warning=linking Valhalla headers from {inc}");
        }

        // Extra -I paths (protobuf, boost, date, …), colon/semicolon-separated
        if let Ok(extra) = env::var("VALHALLA_EXTRA_INCLUDES") {
            for p in extra.split([':', ';']).filter(|s| !s.is_empty()) {
                build.include(p);
            }
        }
        if let Ok(pb) = env::var("PROTOBUF_INCLUDE_DIR") {
            build.include(pb);
        }
        if let Ok(boost) = env::var("BOOST_ROOT") {
            build.include(boost);
        }

        if let Ok(lib) = env::var("VALHALLA_LIB_DIR") {
            println!("cargo:rustc-link-search=native={lib}");
            let link_lib = env::var("VALHALLA_LINK_LIB").unwrap_or_else(|_| "valhalla".into());
            let kind = env::var("VALHALLA_LINK_KIND").unwrap_or_else(|_| "dylib".into());

            if let Ok(pb) = env::var("PROTOBUF_LIB_DIR") {
                println!("cargo:rustc-link-search=native={pb}");
            }
            if let Ok(lz4) = env::var("LZ4_LIB_DIR") {
                println!("cargo:rustc-link-search=native={lz4}");
            }

            let target = env::var("TARGET").unwrap_or_default();
            let android = target.contains("android");

            if kind == "static" {
                // Valhalla 3.5 installs a thin libvalhalla.a; real code is in component archives.
                // --start-group resolves circular deps; pass full paths so order is preserved.
                let components = [
                    "valhalla-tyr",
                    "valhalla-thor",
                    "valhalla-odin",
                    "valhalla-loki",
                    "valhalla-meili",
                    "valhalla-skadi",
                    "valhalla-sif",
                    "valhalla-baldr",
                    "valhalla-midgard",
                    "valhalla-proto",
                    link_lib.as_str(),
                ];
                println!("cargo:rustc-link-arg=-Wl,--start-group");
                for name in components {
                    let archive = format!("{lib}/lib{name}.a");
                    if PathBuf::from(&archive).exists() {
                        println!("cargo:rustc-link-arg={archive}");
                    } else {
                        println!("cargo:warning=missing {archive}");
                    }
                }
                println!("cargo:rustc-link-arg=-Wl,--end-group");
                println!("cargo:rustc-link-lib=dylib=protobuf");
                println!("cargo:rustc-link-lib=dylib=lz4");
                println!("cargo:rustc-link-lib=z");
                if !android {
                    println!("cargo:rustc-link-lib=curl");
                    println!("cargo:rustc-link-lib=sqlite3");
                    println!("cargo:rustc-link-lib=stdc++");
                }
            } else {
                println!("cargo:rustc-link-lib={kind}={link_lib}");
            }

            if android {
                println!("cargo:rustc-link-lib=dylib=c++_shared");
                println!("cargo:rustc-link-lib=log");
                println!("cargo:rustc-link-lib=android");
                // Fail the link if Valhalla/protobuf still unresolved.
                println!("cargo:rustc-link-arg=-Wl,-z,defs");
                // Dart dlsym needs these on the dynamic table (C shim is otherwise LOCAL).
                println!(
                    "cargo:rustc-cdylib-link-arg=-Wl,--export-dynamic-symbol=routing_core_valhalla_is_linked"
                );
                println!(
                    "cargo:rustc-cdylib-link-arg=-Wl,--export-dynamic-symbol=valhalla_is_linked"
                );
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
        println!("cargo:rerun-if-env-changed=VALHALLA_EXTRA_INCLUDES");
        println!("cargo:rerun-if-env-changed=PROTOBUF_INCLUDE_DIR");
        println!("cargo:rerun-if-env-changed=PROTOBUF_LIB_DIR");
        println!("cargo:rerun-if-env-changed=LZ4_LIB_DIR");
        println!("cargo:rerun-if-env-changed=BOOST_ROOT");
    }
}
