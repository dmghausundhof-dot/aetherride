#pragma once
#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__)
#define AETHER_EXPORT __attribute__((visibility("default")))
#else
#define AETHER_EXPORT
#endif

/** Opaque Valhalla actor (config + tile reader). */
typedef struct ValhallaActor ValhallaActor;

/** Create actor from valhalla.json path. NULL on failure. */
AETHER_EXPORT ValhallaActor* valhalla_actor_create(const char* config_path);

AETHER_EXPORT void valhalla_actor_destroy(ValhallaActor* actor);

/**
 * Run /route with Valhalla JSON request body.
 * Returns malloc'd JSON response string; caller frees with valhalla_string_free.
 * NULL on error (check valhalla_last_error).
 */
AETHER_EXPORT char* valhalla_actor_route(ValhallaActor* actor, const char* request_json);

AETHER_EXPORT const char* valhalla_last_error(void);

AETHER_EXPORT void valhalla_string_free(char* s);

/** 1 if compiled against real libvalhalla, 0 if stub. */
AETHER_EXPORT int valhalla_is_linked(void);

#ifdef __cplusplus
}
#endif
