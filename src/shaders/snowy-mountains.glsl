precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float hash(vec2 p) { 
  return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x))));
}

float noise(in vec2 uv) {
  vec2 i = floor(uv);
  vec2 f = fract(uv);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(a, b, u.x) +
            (c - a) * u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

mat2 rotate(float theta) {
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c, -s, s, c);    
}

#define NUM_OCTAVES 10
float fbm(in vec2 uv) {
  float v = 0.0;
  float a = 0.5;
  vec2 shift = vec2(100.0);
  mat2 rot = rotate(0.5);

  for (int i = 0; i < NUM_OCTAVES; ++i) {
    v += a * noise(uv);
    uv = rot * uv * 2.0 + shift;
    a *= 0.5;
  }

  return v;
}

struct sceneObj {
  float dist;
  int id;
  vec3 position;
  vec3 color;
};

struct intersection {
  bool isHit;
  float dist;
  sceneObj obj;
  vec3 normal;
  vec3 p;
  int steps;
};
    
struct camera {
  vec3 origin;
  vec3 direction;
};
    
struct directionalLight {
  vec3 direction;
  vec3 color;
};
    
float sphere(vec3 p, float radius) {
  return length(p) - radius;
}

float plane(vec3 p) {
  return p.y;
}

float box(vec3 p, vec3 b)  {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);    
}
    
sceneObj minObj(sceneObj a, sceneObj b) {
  if (a.dist < b.dist) return a;
  return b;
}
    
sceneObj map(vec3 p) {
  sceneObj p1;
  p.y += pow(fbm(p.xz * 0.15) * 4.0, 1.5);
  p1.dist = box(p + vec3(0, -3.1, 0), vec3(40, 0.01, 40));
  return p1;
}

vec3 normal(vec3 p) {
  vec3 n;
  float e = 0.001;
  n.x = map(p + vec3(e, 0, 0)).dist - map(p - vec3(e, 0, 0)).dist;
  n.y = map(p + vec3(0, e, 0)).dist - map(p - vec3(0, e, 0)).dist;
  n.z = map(p + vec3(0, 0, e)).dist - map(p - vec3(0, 0, e)).dist;
  return normalize(n);
}

#define MAX_STEPS 512
#define NEAR 0.001
#define FAR 256.0
#define STEP_BIAS 0.3;

intersection march(vec3 ro, vec3 rd) {
  intersection i;
  float dist = 1.0;

  for (int j = 0; j < MAX_STEPS; j++) {
    if (dist > FAR) break;

    vec3 p = ro + rd * dist;
    sceneObj obj = map(p);    

    dist += obj.dist * STEP_BIAS;

    if (obj.dist < NEAR) {
      i.isHit = true;
      i.obj = obj;
      i.steps = j;
      i.dist = dist;
      i.normal = normal(p);
      i.p = p;
      break;
    }
  }

  return i;
}

vec3 terrainMat(vec3 p, vec3 n) {
  float noise = noise(p.xy) * 0.5;
  vec3 fog = vec3(0.05) * smoothstep(0.5, -3.5, p.y);
  vec3 snow = vec3(0.3 + noise, 0.3 + noise, 0.4 + noise) * smoothstep(1.5, 2.5, p.y) * n.y;
  vec3 rock = vec3(0.05, 0.05, 0.08) * smoothstep(0.0, 1.7, p.y);
  return pow(fog + snow + rock, vec3(1.0 / 2.0));
}

float shadow(in vec3 p, in vec3 l) {
  float t = 0.001;
  float t_max = 10.0;
  float s = 1.0;

  for (int i = 0; i < 64; i++) {
    if (t > t_max) break;

    float d = map(p + l * t).dist; 
    if (d < NEAR) return 0.0;

    t += d;
    s = min(s, 64.0 * d / t);
  }

  return s;    
}

float ao(in vec3 p, in vec3 n) {
  float e = 1.0;
  float ao = 0.0;
  float weight = 0.25;

  for (int i = 0; i < 6; i++) {
    float d = e * float(i);
    ao += weight * (1.0 - (d - map(p + d * n).dist));
    weight *= 0.75;
  }

  return ao;
}

vec3 render(vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  camera cam;
  cam.origin = vec3(0, 3, 6.5);
  cam.direction = normalize(vec3(uv, -1));

  vec3 color = vec3(0.4, 0.75, 1.0) - 1.1 * cam.direction.y;
  color = mix(color, vec3(0.7, 0.75, 0.8), exp(-3.0 * (cam.direction.y + 0.05)));

  intersection i = march(cam.origin, cam.direction);

  if (i.isHit) {
    vec3 n = i.normal;
    vec3 p = i.p;

    // SUN LIGHT
    directionalLight sun;
    sun.color = vec3(0.7, 0.5, 0.3);
    sun.direction = normalize(vec3(1.0, 0.0, 0.2));
    vec3 sunDiff = sun.color * max(0.5 * dot(n, sun.direction) + 0.5, 0.0);

    // SKY LIGHT
    directionalLight sky;
    sky.color = vec3(0.5, 0.8, 0.9);
    sky.direction = normalize(vec3(0.0, 1.0, 0.0));
    vec3 skyDiff = sky.color * max(0.5 * dot(n, sky.direction) + 0.5, 0.0);

    // SOFT SHADOWS
    float shadows = shadow(p, sun.direction);         

    // AMBIENT
    float ambK = 0.075;
    vec3 ambColor = vec3(0.4, 0.75, 1.0) + 2.1 * cam.direction.y;
    vec3 amb = ambK * ambColor;

    // AMBIENT OCCLUSION
    float ao = ao(p, n);

    // FRESNEL
    float bias = 0.1;
    float scale = 1.0;
    float fresnelIntensity = 0.25;
    float fresnel = fresnelIntensity * (bias + scale * pow(1.0 + dot(sky.direction, n), 2.0));

    // TERRAIN MATERIAL
    vec3 mat = terrainMat(p, n);

    // FOG
    float fog = 1.0 - exp(-i.dist * 0.02);
    vec3 fogColor = vec3(0.5);

    color = skyDiff * fresnel * ao * mat;
    color += sunDiff * shadows * mat;
    color = mix(color, fogColor, fog);
    color += amb;
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

  color = pow(color, vec3(0.4545));

  gl_FragColor = vec4(color, 1.0);
}