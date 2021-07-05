precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

#define EPSILON 1e-2

struct Ray
{
  vec3 origin;
  vec3 direction;
};

struct Plane
{
  vec3 p;
  vec3 n;
};

struct Sphere
{
  vec3 p;
  vec3 n;
  float radius;
};

struct Hit
{
  vec3 p;
  vec3 n;
  float t;
  int id;
};

vec2 normalizeScreenCoords(vec2 fragCoord, vec2 resolution)
{
  vec2 uv = fragCoord / resolution - 0.5;
  uv.x *= resolution.x / resolution.y;
  return uv;
}

float iPlane(Ray ray, Plane plane)
{
  return -ray.origin.y / ray.direction.y;
}

float iSphere(in Ray ray, Sphere sphere)
{
  vec3 oc = ray.origin - sphere.p;
  float a = 1.0;
  float b = 2.0 * dot(oc, ray.direction);
  float c = dot(oc, oc) - sphere.radius * sphere.radius;
  float h = b * b - 4.0 * a * c;
  if (h < 0.0) return -1.0;

  float t = (-b - sqrt(h)) / 2.0;
  return t;    
}

Hit trace(Ray ray)
{
  Plane plane = Plane(vec3(0), vec3(0, 1, 0));
  Sphere sphere = Sphere(vec3(0), vec3(0), 0.5);

  float iPlane = iPlane(ray, plane);
  float iSphere = iSphere(ray, sphere);

  Hit hit;
  hit.id = -1;

  if (iPlane > EPSILON)
  {
    hit.id = 1;
    hit.t = iPlane;
    hit.p = ray.origin + iPlane * ray.direction;
    hit.n = vec3(0, 1, 0);
  }

  if (iSphere > EPSILON)
  {
    hit.id = 2;
    hit.t = iSphere;
    hit.p = ray.origin + iSphere * ray.direction;
    hit.n = hit.p / sphere.radius;
  }

  return hit;
}

vec3 render(in vec2 fragCoord)
{   
  vec2 uv = normalizeScreenCoords(fragCoord, u_resolution);
  vec3 color;

  Ray ray;
  ray.origin = vec3(0, 0.1, 2);
  ray.direction = normalize(vec3(uv.x, uv.y, -1));

  Hit hit = trace(ray);

  if (hit.id != -1)
  {
    vec3 p = hit.p;
    vec3 n = hit.n;

    vec3 pointLight = normalize(vec3(1, 0.5, 1) - p);
    float plDist = length(pointLight);
    float attenuate = 1.0 / (1.0 + 0.25 * pow(plDist, 3.0));

    float diffuse = max(dot(pointLight, n), 0.0);
    float ambient = 0.1 + 0.01 * ray.direction.y;

    vec3 reflectDir = reflect(pointLight, n);
    float spec = pow(max(dot(reflectDir, normalize(ray.direction)), 0.0), 32.0) * 0.25;

    diffuse *= attenuate;
    ambient *= attenuate;

    color += diffuse;
    color += ambient;
    color += spec;
  }

  return color;
}

void main()
{
  vec3 color = render(gl_FragCoord.xy);
  gl_FragColor = vec4(color, 1.0);
}
