/**
 * Thin C API over Valhalla tyr::actor_t.
 *
 * Compile with -DAETHER_VALHALLA_LINKED and link libvalhalla (+ deps).
 * Without the define, exports a stub so the FFI surface always exists.
 */

#include "valhalla_actor_c.h"

#include <cstdlib>
#include <cstring>
#include <mutex>
#include <string>

namespace {
std::mutex g_err_mu;
std::string g_last_error;

void set_error(const std::string& e) {
  std::lock_guard<std::mutex> lock(g_err_mu);
  g_last_error = e;
}

#if defined(AETHER_VALHALLA_LINKED)
char* dup_cstr(const std::string& s) {
  char* out = static_cast<char*>(std::malloc(s.size() + 1));
  if (!out) return nullptr;
  std::memcpy(out, s.c_str(), s.size() + 1);
  return out;
}
#endif
}  // namespace

#if defined(AETHER_VALHALLA_LINKED)

#include <valhalla/tyr/actor.h>
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

struct ValhallaActor {
  boost::property_tree::ptree config;
  valhalla::tyr::actor_t actor;
  explicit ValhallaActor(boost::property_tree::ptree cfg)
      : config(std::move(cfg)), actor(config, true) {}
};

extern "C" ValhallaActor* valhalla_actor_create(const char* config_path) {
  if (!config_path) {
    set_error("null config_path");
    return nullptr;
  }
  try {
    boost::property_tree::ptree pt;
    boost::property_tree::read_json(config_path, pt);
    return new ValhallaActor(std::move(pt));
  } catch (const std::exception& ex) {
    set_error(ex.what());
    return nullptr;
  }
}

extern "C" void valhalla_actor_destroy(ValhallaActor* actor) { delete actor; }

extern "C" char* valhalla_actor_route(ValhallaActor* actor, const char* request_json) {
  if (!actor || !request_json) {
    set_error("null actor or request");
    return nullptr;
  }
  try {
    std::string result = actor->actor.route(std::string(request_json));
    return dup_cstr(result);
  } catch (const std::exception& ex) {
    set_error(ex.what());
    return nullptr;
  }
}

extern "C" int valhalla_is_linked(void) { return 1; }

#else  // stub

struct ValhallaActor {
  std::string config_path;
};

extern "C" ValhallaActor* valhalla_actor_create(const char* config_path) {
  if (!config_path) {
    set_error("null config_path");
    return nullptr;
  }
  auto* a = new ValhallaActor();
  a->config_path = config_path;
  return a;
}

extern "C" void valhalla_actor_destroy(ValhallaActor* actor) { delete actor; }

extern "C" char* valhalla_actor_route(ValhallaActor* /*actor*/, const char* /*request_json*/) {
  set_error(
      "libvalhalla not linked — rebuild with AETHER_VALHALLA_LINKED "
      "(see scripts/routing/build-valhalla-android.sh)");
  return nullptr;
}

extern "C" int valhalla_is_linked(void) { return 0; }

#endif

extern "C" const char* valhalla_last_error(void) {
  std::lock_guard<std::mutex> lock(g_err_mu);
  return g_last_error.c_str();
}

extern "C" void valhalla_string_free(char* s) { std::free(s); }
