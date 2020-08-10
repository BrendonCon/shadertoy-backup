precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float sphere(vec3 ray, float radius) {
  return length(ray) - radius;
}

float scene(vec3 ray) {
  float sphere = sphere(ray - vec3(0.0, 1.0, 0.0), 0.4);
  float plane = ray.y;
  float sceneObjects = min(sphere, plane);
  return sceneObjects;
}

float march(vec3 ro, vec3 rd) {
  float dist = 0.0;
  const float MAX_STEPS = 100.0;
  const float SURF_DIST = 0.001;
  const float FAR = 100.0;
  
  for (float i = 0.0; i < MAX_STEPS; i++) {
    vec3 ray = ro + rd * dist;
    float d = scene(ray);
    if (d < SURF_DIST || d > FAR) break;
    dist += d;
  }
  
  return dist;
}

vec3 normal(in vec3 p) {
  const vec2 e = vec2(0.001, 0);
    
  return normalize(vec3(
    scene(p + e.xyy) - scene(p - e.xyy), 
    scene(p + e.yxy) - scene(p - e.yxy),	
    scene(p + e.yyx) - scene(p - e.yyx)
  ));
}

float diffuse(vec3 ray) {
  vec3 lightPosition = vec3(0.0, 3.0, 1.0);
  vec3 surfaceNormal = normal(ray);
  float diffuse = clamp(dot(surfaceNormal, normalize(lightPosition - ray)), 0.0, 1.0);
  return diffuse;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 ro = vec3(0.0, 1.0, 3.0);
  vec3 rd = normalize(vec3(uv.x, uv.y, -1.0));
  float d = march(ro, rd);

  vec3 ray = ro + rd * d;
  float diffuse = diffuse(ray);
  vec3 color = vec3(diffuse);

  gl_FragColor = vec4(color, 1.0);
}
