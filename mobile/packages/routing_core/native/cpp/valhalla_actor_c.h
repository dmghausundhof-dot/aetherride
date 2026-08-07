#pragma once
#ifdef __cplusplus
extern "C" {
#endif

/** Opaque Valhalla actor (config + tile reader). */
typedef struct ValhallaActor ValhallaActor;

/** Create actor from valhalla.json path. NULL on failure. */
ValhallaActor* valhalla_actor_create(const char* config_path);

void valhalla_actor_destroy(ValhallaActor* actor);

/**
 * Run /route with Valhalla JSON request body.
 * Returns malloc'd JSON response string; caller frees with valhalla_string_free.
 * NULL on error (check valhalla_last_error).
 */
char* valhalla_actor_route(ValhallaActor* actor, const char* request_json);

const char* valhalla_last_error(void);

void valhalla_string_free(char* s);

/** 1 if compiled against real libvalhalla, 0 if stub. */
int valhalla_is_linked(void);

#ifdef __cplusplus
}
#endif
