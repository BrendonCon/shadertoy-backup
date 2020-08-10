precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float sphere(vec3 ray, float radius) {
  return length(ray) - radius;
}

float scene(vec3 ray) {
  float sphere = sphere(ray - vec3(0.0, 0.9, 0.0), 0.4);
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

float phong(vec3 ro, vec3 rd, vec3 ray, vec3 lightPosition) {
  float ambient = 0.01;

  vec3 lightDirection = normalize(lightPosition - ray);
  vec3 surfaceNormal = normal(ray);
  float diffuse = max(dot(surfaceNormal, lightDirection), 0.0);

  vec3 viewPosition = vec3(-1.5, 2.0, -5.0);
  vec3 viewDirection = normalize(viewPosition - ro);
  vec3 reflectDirection = reflect(lightDirection, surfaceNormal);
  float specStrength = 0.25;
  float specExp = 32.0;
  float spec = pow(max(dot(viewDirection, reflectDirection), 0.0), specExp) * specStrength;

  return ambient + diffuse + spec;
}

float shadow(vec3 ray, vec3 lightPosition) {
  vec3 lightDirection = normalize(lightPosition - ray);
  float shadowStrength = 0.5;
  vec3 surfaceNormal = normal(ray);
  float d = march(ray + surfaceNormal, lightDirection);
  
  if (d < length(lightPosition - ray)) {
    return shadowStrength;
  }

  return 1.0;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 ro = vec3(0.0, 1.0, 3.0);
  vec3 rd = normalize(vec3(uv.x, uv.y, -1.0));
  float d = march(ro, rd);

  vec3 lightPosition = vec3(0.0, 5.0, 2.0);
  vec3 ray = ro + rd * d;

  float phong = phong(ro, rd, ray, lightPosition);
  float shadow = shadow(ray, lightPosition);
  vec3 color = vec3(phong * shadow);

  gl_FragColor = vec4(color, 1.0);
}
