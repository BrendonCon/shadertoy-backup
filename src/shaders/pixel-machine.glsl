precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec2 mouse;

struct Material {
  int id;
  vec3 diffuse;
  vec3 specular;
};

struct Object {
  int id;
  vec3 position;
  float dist;
  Material mat;
};

struct Intersection {
  vec3 point;
  float dist;
  vec3 normal;
  int steps;
  Material mat;
  bool isHit;
};

struct Ray {
  vec3 origin;
  vec3 direction;
};

struct Light {
  vec3 position;
  vec3 color;
};
    
Intersection march(vec3 ro, vec3 rd);
Object scene(vec3 p);
    
vec3 normal(vec3 p) {
  vec3 n;
  float e = 0.0001;
  n.x = scene(p + vec3(e, 0, 0)).dist - scene(p - vec3(e, 0, 0)).dist;
  n.y = scene(p + vec3(0, e, 0)).dist - scene(p - vec3(0, e, 0)).dist;
  n.z = scene(p + vec3(0, 0, e)).dist - scene(p - vec3(0, 0, e)).dist;
  return normalize(n);
}
    
float box(vec3 p, vec3 size) {
  return length(max(abs(p) - size, 0.0));
}
    
float sphere(vec3 p, float radius) {
  return length(p) - radius;
}

vec3 calcLighting(Intersection i, Ray camera) {
  vec3 color;
  Light light;
  light.position = normalize(vec3(2.0 * sin(u_time * 0.5), 2.0, 3.0));
  light.color = vec3(2.5);

  if (i.isHit) {
    vec3 p = i.point;
    vec3 n = i.normal;
    vec3 l = light.position;
    vec3 v = normalize(camera.origin - p);
    vec3 h = normalize(l + v);

    vec3 diffuse = i.mat.diffuse * clamp(dot(n, l), 0.0, 1.0) * light.color;
    color += diffuse;    

    float spec = clamp(dot(h, n), 0.0, 1.0);
    color += vec3(pow(spec, 40.0)) * 0.25;

    Intersection shadows = march(p + l * 0.01, l);
    if (shadows.isHit) color *= 0.4;    
  }

  return color;
}

Object closestObject(Object a, Object b) {
  if (a.dist < b.dist) return a;
  return b;
}
    
Object scene(vec3 p) {
  Object sphere1;
  sphere1.position.x = mouse.x * 3.0;
  sphere1.position.z = -mouse.y * 7.0;
  sphere1.dist = sphere(p - sphere1.position, 0.5);
  sphere1.mat.diffuse = vec3(0.2);
  sphere1.mat.id = 1;

  Object box1;
  box1.dist = box(p + vec3(0, 0.5, 0), vec3(2.5, 0.025, 5.0));

  p *= 4.0;
  float c = mod(floor(p.x) + floor(p.z), 2.0);
  vec3 planeDiffuse = vec3(0.8 + 0.1 * c, 0.3 + 0.55 * c, 0.15 - 0.1 * c) * 0.8;
  box1.mat.diffuse = vec3(planeDiffuse);

  return closestObject(sphere1, box1);
}

#define MAX_STEPS 256
#define NEAR 0.0001
#define FAR 100.0
#define STEP_BIAS 0.5
    
Intersection march(vec3 ro, vec3 rd) {
  float t = 0.0;
  Intersection i;

  for (int j = 0; j < MAX_STEPS; j++) {
    if (t > FAR) break;

    vec3 p = ro + t * rd;
    Object o = scene(p);

    t += o.dist * STEP_BIAS;

    if (o.dist < NEAR) {
      i.point = p;
      i.steps = j;
      i.isHit = true;
      i.normal = normal(p);
      i.mat = o.mat; 
      i.dist = t;
      break;
    }
  }

  return i;
}
    
vec3 render(vec2 fragCoord)  {
  vec2 uv = fragCoord / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  Ray camera;
  camera.origin = vec3(0, 2.2, 6);
  camera.direction = normalize(vec3(uv.x * 0.3, uv.y * 0.3 - 0.3, -1));

  Intersection i = march(camera.origin, camera.direction);

  vec3 bgColor = vec3(0.34, 0.55, 0.85);
  vec3 color = bgColor;

  if (i.isHit) {
    color = calcLighting(i, camera);

    if (i.mat.id == 1) {
      vec3 n = i.normal;
      vec3 p = i.point;
      vec3 incident = normalize(p - camera.origin);

      camera.direction = reflect(incident, n);
      camera.origin = p + camera.direction * 0.001; 	

      i = march(camera.origin, camera.direction);

      color += bgColor;
      if (i.isHit) color = calcLighting(i, camera);
    }
  }

  return color;
}

void main() {
  mouse = u_mouse.xy / u_resolution.xy - 0.5;

  vec3 color;
  color += render(gl_FragCoord.xy + vec2(0.2));
  color += render(gl_FragCoord.xy + vec2(-0.2, 0.2));
  color += render(gl_FragCoord.xy + vec2(-0.2));
  color += render(gl_FragCoord.xy + vec2(0.2, -0.2));
  color /= 4.0;

  gl_FragColor = vec4(color, 1.0);
}
