precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

struct Ray 
{
  vec3 origin;
  vec3 direction;
};

struct Material
{
  int id;
  vec3 diffuse;
  vec3 specular;
  float reflectivity;
};

struct SceneObject
{
  int id;
  float dist;
  Material mat;
};

struct Intersection 
{
  vec3 point;
  vec3 normal;
  bool isHit;
  int steps;
  float dist;
  SceneObject obj;
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

float box(in vec3 p, in vec3 size)
{
  return length(max(abs(p) - size, 0.0));
}

SceneObject getClosestObject(SceneObject a, SceneObject b)
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

vec2 normalizeScreenCoords(vec2 fragCoord, vec2 resolution)
{
  vec2 uv = fragCoord / resolution - 0.5;
  uv.x *= resolution.x / resolution.y;
  return uv;
}

vec3 getObjectColor(vec3 p) 
{
  vec3 ip = floor(p);
  float rnd = fract(sin(dot(ip, vec3(27.17, 112.61, 57.53))) * 43758.5453);
  vec3 col = (fract(dot(ip, vec3(0.5))) > 0.001) ? 0.5 + 0.45 * cos(mix(3.0, 4.0, rnd) + vec3(0.9, 0.45, 1.5)): vec3(0.7 + 0.3 * rnd);

  if (fract(rnd * 1183.5437 + 0.42) > 0.65) col = col.zyx;
  return col;
}

SceneObject scene(in vec3 p)
{
  SceneObject obj;
  obj.mat.diffuse = getObjectColor(p * 0.5);

  p = mod(p, 2.0) - 1.0;
  obj.mat.specular = vec3(1);
  obj.mat.reflectivity = 0.05;
  obj.dist = box(p, vec3(0.4));

  return obj;
}

vec3 calcNormal(in vec3 p)
{
  vec2 e = vec2(1e-2, 0);
  vec3 n;
  n.x = scene(p + e.xyy).dist - scene(p - e.xyy).dist;
  n.y = scene(p + e.yxy).dist - scene(p - e.yxy).dist;
  n.z = scene(p + e.yyx).dist - scene(p - e.yyx).dist;
  return normalize(n);
}

#define MAX_STEPS 256
#define STEP_BIAS 0.3
#define NEAR 1e-2
#define FAR 20.0

Intersection march(in vec3 ro, in vec3 rd)
{
  Intersection i;
  float t = 1e-2;

  for (int j = 0; j < MAX_STEPS; j++)
  {
    if (abs(t) > FAR) break;

    vec3 p = ro + t * rd;
    SceneObject obj = scene(p);

    if (abs(obj.dist) <= NEAR)
    {
      i.isHit = true;
      i.point = p;
      i.normal = calcNormal(p);
      i.steps = j;
      i.obj = obj;
      i.dist = t;
      break;
    }

    t += obj.dist * STEP_BIAS;
  }

  return i;
}

vec3 getColor(Intersection i, in vec3 ro, in vec3 rd)
{
  vec3 color = vec3(0);
  vec3 point = i.point;
  vec3 normal = i.normal;
  SceneObject sceneObj = i.obj;   

  vec3 lightPosition = vec3(0, 1, 1.0) - rd;
  vec3 lightDirection = normalize(lightPosition);
  float lightDist = max(length(lightDirection), 0.001);
  float atten = 1.0 / (1.0 + lightDist * 0.1 + lightDist * lightDist);

  float diff = max(dot(lightDirection, normal), 0.0);
  vec3 diffuse = sceneObj.mat.diffuse * diff;

  float ambStrength = 1.0;
  vec3 ambColor = vec3(0.01);
  vec3 ambient = ambStrength * ambColor;

  vec3 r = reflect(lightDirection, normal);
  float specStrenth = 0.5;
  float specExp = 16.0;
  float spec = pow(max(dot(r, rd), 0.0), specExp);
  vec3 specular = specStrenth * spec * sceneObj.mat.specular;

  float fresnel = clamp(1.0 + dot(rd, normal), 0.0, 1.0);
  float ao = pow(1.0 - float(i.steps) / float(MAX_STEPS), 1.0);

  if (i.isHit) 
  {
    color += diffuse;
    color += ambient;
    color += specular;
    color += fresnel * 0.1;
    color *= ao * 1.5;
    color *= atten;
  }

  return color;
}

vec3 render(in vec2 fragCoord)
{
  vec2 uv = normalizeScreenCoords(fragCoord, u_resolution);

  Ray camera;
  camera.origin = vec3(0, 0, 2.0 - u_time);
  camera.direction = normalize(vec3(uv, -1));

  camera.direction.xz *= rotate(u_time * 0.1);
  camera.direction.yx *= rotate(sin(u_time * 0.2));
  camera.direction.yz *= rotate(cos(u_time * 0.25));

  Intersection i = march(camera.origin, camera.direction);
  vec3 color = getColor(i, camera.origin, camera.direction);

  vec3 r = reflect(camera.direction, i.normal);
  Intersection reflections = march(i.point + i.normal * 0.01, r);
  vec3 refColor = getColor(reflections, reflections.point, r);
  if (i.isHit) color += refColor * i.obj.mat.reflectivity;

  float fog = smoothstep(0.0, 0.2, max(i.dist / float(MAX_STEPS), 0.01));
  color = mix(color, vec3(0), fog);

  return color;
}

void main()
{
  vec3 color;
  color += render(gl_FragCoord.xy + vec2(0.2));
  color += render(gl_FragCoord.xy + vec2(-0.2, 0.2));
  color += render(gl_FragCoord.xy + vec2(-0.2));
  color += render(gl_FragCoord.xy + vec2(0.2, -0.2));
  color /= 4.0;

  color *= color * 6.0;
  color = reinhardToneMap(color);
  color = gammaCorrect(color);

  gl_FragColor = vec4(color, 1.0);
}
