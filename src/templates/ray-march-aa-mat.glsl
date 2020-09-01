precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float sphere(vec3 p, float radius) {
  return length(p) - radius;
}

float scene(vec3 p, out int matId) {
  float sphere = sphere(p, 0.5);

  float dist = 10e7;
  dist = min(dist, sphere);

  if (dist == sphere) matId = 1;

  return dist;
}

float scene(vec3 p) {
  int matId = -1;
  return scene(p, matId);
}

#define MAX_STEPS 200
#define SURF_DIST 0.001
#define FAR 200.0

float trace(vec3 ro, vec3 rd, out int matId) {
  float t = 0.0;

  for (int i = 0; i < MAX_STEPS; i++) {
    matId = -1;
    if (t > FAR) break;

    vec3 p = ro + rd * t;
    float d = scene(p, matId);

    if (d < SURF_DIST) break;
    t += d;
  }

  return t;
}

vec3 normal(vec3 p) {
  vec3 n;
  float e = 0.001;
  n.x = scene(p + vec3(e, 0, 0)) - scene(p - vec3(e, 0, 0));
  n.y = scene(p + vec3(0, e, 0)) - scene(p - vec3(0, e, 0));
  n.z = scene(p + vec3(0, 0, e)) - scene(p - vec3(0, 0, e));
  return normalize(n);
}

vec3 render(vec2 fragCoord) {
  vec2 uv = fragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 ro = vec3(0, 0, 2);
  vec3 rd = normalize(vec3(uv, -1));

  int matId = -1;
  float t = trace(ro, rd, matId);
  vec3 p = ro + rd * t;

  vec3 color;

  if (matId == 1) {
    vec3 n = normal(p);
    vec3 l = normalize(vec3(0.25, 1.0, 1.0) - p);
    float lambert = max(dot(n, l), 0.0);

    float diffStr = 0.75;
    vec3 diffColor = vec3(1.0, 0.9, 0.7);
    vec3 diff = diffStr * diffColor * lambert;

    vec3 ambColor = vec3(0.5, 0.6, 0.7);
    float ambStr = 0.1;
    vec3 amb = ambStr * ambColor;

    color = amb + diff;
  }

  return color;
}

void main() {
  vec3 color;
  color += render(gl_FragCoord.xy + vec2(0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25, 0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25));
  color += render(gl_FragCoord.xy + vec2(0.25, -0.25));
  color /= 4.0;
  color = sqrt(color);

  gl_FragColor = vec4(color, 1);
}
