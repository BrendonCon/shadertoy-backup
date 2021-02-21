
precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

#define MAX_STEPS 512.0
#define STEP_BIAS 0.75
#define NEAR 1e-3
#define FAR 40.0

struct Ray 
{
  vec3 origin;
  vec3 direction;
};

struct Material
{
  int id;
  vec3 ambient;
  vec3 diffuse;
  vec3 specular;
  float shininess;
  float reflectivity;
  float ior;
  float fresnel;
  bool shadows;
};

struct SceneObject
{
  int id;
  float dist;
  Material mat;
};

struct DirectionalLight
{
  vec3 direction;
  vec3 ambient;
  vec3 diffuse;
  vec3 specular;
};

mat2 rotate(float theta)
{
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c, -s, s, c);
}

float plane(in vec3 p, in vec3 n)
{
  return max(dot(p, n), 0.0);
}

float sphere(in vec3 p, float radius)
{
  return length(p) - radius;
}

float boundingBox(in vec3 p, vec3 b, float e)
{
  p = abs(p) - b;
  vec3 q = abs(p + e) - e;
  return min(min(
      length(max(vec3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0),
      length(max(vec3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0)),
      length(max(vec3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0));
}

SceneObject closestObject(SceneObject a, SceneObject b)
{
  if (a.dist < b.dist) return a;
  return b;
}

vec3 reinhardToneMap(vec3 color)
{
  return color / (color + vec3(1.0));
}

vec3 gammaCorrect(vec3 color)
{
  return pow(color, vec3(0.4545));
}

vec2 normalizeScreenCoords(in vec2 fragCoord, in vec2 resolution)
{
  vec2 uv = fragCoord / resolution - 0.5;
  uv.x *= resolution.x / resolution.y;
  return uv;
}

SceneObject getPlane(in vec3 p)
{
  p.z -= u_time;

  SceneObject pl;
  pl.mat.id = 1;
  pl.mat.shininess = 32.0;
  pl.mat.fresnel = 0.02;
  pl.mat.shadows = true;
  pl.mat.diffuse = vec3(0.1, 0.2, 0.3);

  vec3 q = p * 3.0;
  vec3 pattern = vec3(step(fract(q.x * 3.0) + fract(q.z * 3.0), 1.0));
  pl.mat.diffuse = vec3(mod(floor(q.x) + floor(q.z), 2.0));

  pl.mat.specular = vec3(0.1);
  pl.mat.reflectivity = 0.05;
  pl.dist = plane(p - vec3(0, -0.75, 0), vec3(0, 1, 0));

  return pl;
}

SceneObject getSphere(in vec3 p)
{
  float id = floor(abs(p.z));
      
  p.x += sin(id + u_time) * 0.3;
  p.z = mod(p.z, 1.0) - 0.5;

  SceneObject s;
  s.mat.id = 2;
  s.mat.diffuse = vec3(1.5, 0.0, 0.0);
  s.mat.shadows = true;
  s.mat.reflectivity = 0.085;
  s.mat.shininess = 16.0;
  s.mat.specular = vec3(0.55);
  s.mat.fresnel = 0.4;
  s.dist = sphere(p - vec3(0, sin(id * 4531.2 + u_time * id) * 0.2, 0.0), 0.15);
  return s;
}

SceneObject getBoundingBox(in vec3 p)
{
  p.z -= u_time;
  float id = floor(abs(p.z)); 
  p.xy *= rotate(id);
  p.z = mod(p.z, 1.0) - 0.5;

  SceneObject bb;
  bb.dist = boundingBox(p, vec3(0.9, 0.9, 0.04), 0.04) - dot(p, p) * 0.02; 
  bb.mat.id = 3;
  bb.mat.shininess = 8.0;
  bb.mat.reflectivity = 0.1;
  bb.mat.shadows = true;
  bb.mat.diffuse = vec3(0.8);
  bb.mat.specular = vec3(1.5);
  bb.mat.fresnel = 0.5;

  return bb;
}

SceneObject scene(in vec3 p)
{
  p.y -= sin(p.z * 2.0) * 0.1;

  SceneObject pl = getPlane(p);
  SceneObject s = getSphere(p);
  SceneObject bb = getBoundingBox(p);

  SceneObject obj = closestObject(pl, s);
  obj = closestObject(obj, bb);

  return obj;
}

vec3 calcNormal(in vec3 p)
{
  vec2 e = vec2(1e-3, 0);

  return normalize(vec3(
    scene(p + e.xyy).dist - scene(p - e.xyy).dist,
    scene(p + e.yxy).dist - scene(p - e.yxy).dist,
    scene(p + e.yyx).dist - scene(p - e.yyx).dist
  ));
}

float raymarch(in vec3 ro, in vec3 rd)
{   
  float t;

  for (float i = 0.0; i < MAX_STEPS; i++)
  {
    SceneObject obj = scene(ro + t * rd);
    if ((obj.dist) < NEAR || abs(t) > FAR) return t;
    t += obj.dist * STEP_BIAS;
  }

  return FAR;
}

float calcSoftshadow(in vec3 ro, in vec3 rd, float tmin, float tmax, const float k)
{
  float res = 1.0;
  float t = tmin;

  for(int i= 0; i < 50; i++)
  {
    SceneObject o = scene(ro + rd * t);
    float h = o.dist;
    if (o.mat.shadows == false) return 1.0;
    res = min(res, k * h / t);
    t += clamp(h, 0.02, 0.20);
    if (res < 0.005 || t > tmax) break;
  }

  return clamp(res, 0.0, 1.0);
}

float ao(in vec3 p, in vec3 n)
{
  float e = 1.0;
  float res = 0.0;
  float weight = 0.75;

  for (int i = 0; i <= 5; i++)
  {
    float d = e * float(i);
    SceneObject o = scene(p + d * n);
    float h = o.dist;
    if (o.mat.shadows == false) return 1.0;
    res += weight * (1.0 - (d - o.dist));
    weight *= 0.4;
  }

  return res;
}

vec3 envMap(vec3 rd)
{
  vec3 c1 = vec3(1.0);
  vec3 c2 = vec3(0.0, 0.1, 0.3);
  float y = rd.y * 0.75 + 0.65;
  return mix(c1, c2, pow(y, 1.0)) * 1.5;
}

vec3 getColor(SceneObject obj, vec3 p, vec3 n, in vec3 ro, in vec3 rd)
{
  vec3 color = vec3(0);
  Material mat = obj.mat;

  vec3 lightPosition = vec3(0.0, 1.0, 1.0);
  vec3 lightDirection = normalize(lightPosition);

  float diff = max(dot(lightDirection, n), 0.0);
  vec3 diffuse = mat.diffuse * diff;

  float ambStrength = 1.0;
  vec3 ambColor = vec3(0.15);
  vec3 ambient = ambStrength * ambColor * rd.y;

  vec3 r = reflect(lightDirection, n);
  float spec = pow(max(dot(r, rd), 0.0), mat.shininess);
  vec3 specular = spec * mat.specular;

  float fresnel = pow(clamp(1.0 + dot(rd, n), 0.0, 1.0), 3.0);
  float occ = ao(p + n * 0.25, n);
  float shad = max(calcSoftshadow(p + n * 0.1, lightDirection, 0.0, 1.5, 16.0), 0.5);

  color += ambient;
  color += diffuse * shad * occ;
  color += specular;
  color += fresnel * mat.fresnel;
  color = mix(color, envMap(rd), 0.15);

  return color;
}

vec3 render(in vec2 fragCoord)
{
  vec2 uv = normalizeScreenCoords(fragCoord, u_resolution.xy);

  Ray camera;
  camera.origin = vec3(0.1, 0.1, -0.75);
  camera.direction = normalize(vec3(uv, -1));

  vec3 bgColor = envMap(camera.direction);
  vec3 color = bgColor;

  vec3 ro = camera.origin;
  vec3 rd = camera.direction;
  float t = raymarch(ro, rd);
  vec3 p = ro + t * rd;
  vec3 n = calcNormal(p);
  SceneObject obj1 = scene(p);

  if (t < FAR)
  {    
    color = getColor(obj1, p, n, ro, rd);  

    vec3 r = reflect(rd, n);
    float t = raymarch(p + r * 0.1, r);
    vec3 p = p + t * r;
    vec3 n = calcNormal(p);
    SceneObject obj2 = scene(p);
    if (t < FAR) color += getColor(obj2, p, n, ro, rd) * obj1.mat.reflectivity;  
  }

  float fog = smoothstep(0.0, 0.001, pow(max((t + 1.0) / float(MAX_STEPS * 2.0), 0.0), 1.5));
  color = mix(color, bgColor, fog);
  color *= smoothstep(1.35, 0.35, length(uv));

  return color;
}

vec3 superSampleAA(in vec2 fragCoord)
{
  vec3 color;
  color += render(fragCoord + vec2(0.25));
  color += render(fragCoord + vec2(-0.25, 0.25));
  color += render(fragCoord + vec2(-0.25));
  color += render(fragCoord + vec2(0.25, -0.25));
  color /= 4.0;
  return color;
}

void main()
{
  vec3 color = superSampleAA(gl_FragCoord.xy);

  color = color * color;
  color *= 1.1;
  color = reinhardToneMap(color);
  color = gammaCorrect(color);

  gl_FragColor = vec4(color, 1.0);
}
