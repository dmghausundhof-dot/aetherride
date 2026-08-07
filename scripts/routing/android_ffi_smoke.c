/* Minimal Android ABI smoke for librouting_core.so (offline_graph). */
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  double from_lat, from_lng, to_lat, to_lng;
  const char *profile;
  const char *tiles_path;
} RouteRequest;

typedef struct {
  double distance_m, duration_s;
  uint32_t coordinate_count;
} RouteSummary;

typedef int32_t (*tiles_ok_fn)(const char *);
typedef int32_t (*route_fn)(const RouteRequest *, RouteSummary *, double *, uint32_t);

int main(int argc, char **argv) {
  const char *lib = argc > 1 ? argv[1] : "librouting_core.so";
  const char *tiles = argc > 2 ? argv[2] : "/data/local/tmp/routing";
  void *h = dlopen(lib, RTLD_NOW);
  if (!h) {
    fprintf(stderr, "dlopen failed: %s\n", dlerror());
    return 1;
  }
  tiles_ok_fn tiles_ok = (tiles_ok_fn)dlsym(h, "routing_core_tiles_ok");
  route_fn route = (route_fn)dlsym(h, "routing_core_route");
  if (!tiles_ok || !route) {
    fprintf(stderr, "dlsym failed\n");
    return 2;
  }
  if (tiles_ok(tiles) != 1) {
    fprintf(stderr, "tiles_ok=0 for %s\n", tiles);
    return 3;
  }
  RouteRequest req = {47.99, 7.85, 47.95, 7.92, "mtb_enduro", tiles};
  RouteSummary out = {0};
  int32_t code = route(&req, &out, NULL, 0);
  if (code != 0 && code != 5) { /* OK or BUFFER_TOO_SMALL */
    fprintf(stderr, "route probe code=%d\n", code);
    return 4;
  }
  uint32_t n = out.coordinate_count;
  double *buf = (double *)calloc(n * 2, sizeof(double));
  code = route(&req, &out, buf, n);
  free(buf);
  if (code != 0) {
    fprintf(stderr, "route code=%d\n", code);
    return 5;
  }
  printf("SMOKE_OK distance_m=%.1f duration_s=%.1f coords=%u\n", out.distance_m,
         out.duration_s, out.coordinate_count);
  return 0;
}
