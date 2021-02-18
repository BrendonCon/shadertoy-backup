precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

#define MAX_STEPS 512.0
#define STEP_BIAS 0.5
#define FAR 30.0
#define NEAR 1e-3
#define EPSILON 1e-4
#define t iTime

#define PI 3.14159
#define TAU PI * 2

struct Ray
{
  vec3 origin;
  vec3 direction;
};

struct Material
{
  int id;
  vec3 diffuse;
  vec3 ambient;
  vec3 specular;
  float ao;
  float castsShadow;
  float shininess;
  float reflectivity;
  float fresnel;
};

struct SceneObject 
{
  int id;
  Material mat;
  float dist;
};

struct Intersection
{
  bool isHit;
  vec3 p;
  vec3 n;
  vec3 r;
  float dist;
  float steps;
  SceneObject obj;
};

vec3 glow;

mat2 rotate(float theta)
{
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c, -s, s, c);
}

float sphere(in vec3 p, float radius)
{
  return length(p) - radius;
}

float plane(in vec3 p, in vec3 n)
{
  return max(dot(p, n), 0.0);
}

float box(in vec3 p, in vec3 s)
{
  return length(max(abs(p) - s, 0.0));
}

float boundingBox(vec3 p, vec3 b, float e)
{
  p = abs(p) - b;
  vec3 q = abs(p + e) - e;
  return min(min(
    length(max(vec3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0),
    length(max(vec3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0)),
    length(max(vec3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0));
}

vec3 gammaCorrect(in vec3 color)
{
  return pow(color, vec3(0.4545));
}

vec2 normalizeScreenCoords(vec2 uv, vec2 resolution)
{ 
  uv = uv / resolution.xy - 0.5;
  uv.x *= resolution.x / resolution.y;
  return uv;
}

SceneObject closestObject(in SceneObject a, in SceneObject b)
{
  if (a.dist < b.dist) return a;
  return b;
}

vec3 reinhardToneMap(const vec3 color) 
{
  return color / (color + vec3(1.0));
}

SceneObject scene(in vec3 p)
{
  SceneObject obj;
  obj.mat.id = 1;
  obj.dist = 100.0;

  glow += 0.15 / (0.001 + pow(length(p) - 0.01, 2.0)) * 0.001;

  float t = u_time * 0.5;

  for (float i = 0.0; i < 6.0; i++)
  {
    float n = i / 5.0;
    float theta = mix(0.0, 6.28, n);
    float size = mix(0.5, 0.01, n);

    p.xz *= rotate(theta + n + t);
    obj.dist = min(boundingBox(p, vec3(size), 0.015), obj.dist);
  }

  return obj;
}

vec3 calcNormal(in vec3 p, float eps)
{
  return normalize(vec3(
    scene(p + vec3(eps, 0, 0)).dist - scene(p - vec3(eps, 0, 0)).dist,
    scene(p + vec3(0, eps, 0)).dist - scene(p - vec3(0, eps, 0)).dist,
    scene(p + vec3(0, 0, eps)).dist - scene(p - vec3(0, 0, eps)).dist
  ));
}

Intersection march(in vec3 ro, in vec3 rd)
{
  Intersection i;
  float t;

  for (float j = 0.0; j < MAX_STEPS; j++)
  {
    if (abs(t) > FAR) break;

    vec3 p = ro + t * rd;
    SceneObject obj = scene(p);

    if (abs(obj.dist) < NEAR)
    {
      i.isHit = true;
      i.p = p;
      i.n = calcNormal(p, EPSILON);
      i.r = reflect(rd, i.n);
      i.dist = t;
      i.obj = obj;
      i.steps = j;
      break;
    }

    t += obj.dist * STEP_BIAS;
  }

  return i;
}

float ao(in vec3 p, in vec3 n)
{
  float e = 0.25;
  float res = 0.0;
  float weight = 0.25;

  for (int i = 0; i <= 5; i++)
  {
    float d = e * float(i);
    res += weight * (1.0 - (d - scene(p + d * n).dist));
    weight *= 0.9;
  }

  return res;
}

float shadow(in vec3 p, in vec3 l)
{
  float t = 0.01; 
  float t_max = 3.0;
  float k = 4.0;
  float res = 1.0;

  for (int i = 0; i < 32; i++) 
  {
    if (t > t_max) break;

    float d = scene(p + l * t).dist; 
    if (d < 0.001) return 0.0;

    t += d * 0.25;
    res = min(res, k * d / t);
  }

  return res;    
}

Material getMaterial(in Intersection i, in vec3 ro, in vec3 rd)
{
  vec3 p = i.p;
  vec3 n = i.n;
  SceneObject obj = i.obj;
  Material mat = obj.mat;

  if (mat.id == 1)
  {
    mat.diffuse = vec3(0.8);   
    mat.specular = vec3(0.5);
    mat.reflectivity = 0.95;
    mat.ambient = vec3(1.0);
    mat.shininess = 0.75;
    mat.fresnel = 0.9;
    mat.ao = 1.0;    
  }

  return mat;
}

vec3 calcLighting(in Intersection i, in vec3 ro, in vec3 rd)
{
  vec3 p = i.p;
  vec3 n = i.n;
  SceneObject obj = i.obj;
  Material mat = getMaterial(i, ro, rd);

  vec3 l = vec3(0, 0.0, 0.0);
  vec3 lp = normalize(l - p);

  float lambert = max(dot(lp, n), 0.0) * 0.5 + 0.5;
  vec3 diff = mat.diffuse * lambert * vec3(0.8,0.7,0.9); 

  float ambStrength = 0.01;
  vec3 ambient = mat.ambient * ambStrength;

  vec3 r = reflect(lp, n);
  float specExp = 16.0;
  float spec = pow(max(dot(r, rd), 0.0), specExp) * mat.shininess;

  float fresnel = pow(clamp(1.0 + dot(rd, n), 0.0, 1.0), 2.0) * mat.fresnel;
  float ao = ao(p, n);
  float shad = shadow(p + n * 0.1, l); 

  vec3 color;
  color += diff;
  color += ambient;
  color += spec;
  color += fresnel;
  color *= shad;
  color += ambient;
  color *= ao;

  return color;
}

vec3 render(in vec2 fragCoord)
{
  vec2 uv = normalizeScreenCoords(fragCoord, u_resolution);
  vec3 color = vec3(0.0);

  Ray camera;
  camera.origin = vec3(0.0, 0, 1.75);
  camera.direction = normalize(vec3(uv, -1));

  // first pass
  Intersection i = march(camera.origin, camera.direction);
  if (i.isHit) color = calcLighting(i, camera.origin, camera.direction);
  color += glow * vec3(0.8, 0.7, 0.9) * 5.5;

  // reflection pass
  Material mat = getMaterial(i, camera.origin, camera.direction);
  vec3 r = reflect(normalize(camera.direction), i.n);
  Intersection ref = march(i.p + r * 0.1, r);
  if (ref.isHit) color += calcLighting(ref, i.p, r) * mat.reflectivity;

  return color;
}

void main()
{
  vec3 color = render(gl_FragCoord.xy);
  color *= pow(color, vec3(2.0));
  color = reinhardToneMap(color);
  gl_FragColor = vec4(gammaCorrect(color), 1.0);
}
