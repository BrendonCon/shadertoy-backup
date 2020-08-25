precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

#define SURF_DIST 0.001
#define MAX_STEPS 200
#define FAR 200.0

struct sceneObj {
  float matId;
  float dist;
  vec3 position;
};  
    
struct light {
  float intensity;
  vec3 position;
  vec3 color;
  vec3 direction;
};

sceneObj[5] getSceneObjs(vec3 p) {
  sceneObj sceneObjs[5]; 

  sceneObj sphere1;
  sphere1.matId = 1.0;
  sphere1.dist = length(p - sphere1.position) - 0.5; 
  sceneObjs[0] = sphere1;

  sceneObj sphere2;
  sphere2.matId = 2.0;
  sphere2.position = vec3(1.0, 0.0, 1.0);
  sphere2.dist = length(p - sphere2.position) - 0.5; 
  sceneObjs[1] = sphere2;

  sceneObj sphere3;
  sphere3.matId = 3.0;
  sphere3.position = vec3(-1.0, 0.0, 1.0);
  sphere3.dist = length(p - sphere3.position) - 0.5; 
  sceneObjs[2] = sphere3;

  sceneObj sphere4;
  sphere4.matId = 4.0;
  sphere4.position = vec3(-2.0, 0.0, 2.0);
  sphere4.dist = length(p - sphere4.position) - 0.5; 
  sceneObjs[3] = sphere4;

  sceneObj sphere5;
  sphere5.matId = 5.0;
  sphere5.position = vec3(2.0, 0.0, 2.0);
  sphere5.dist = length(p - sphere5.position) - 0.5; 
  sceneObjs[4] = sphere5;

  return sceneObjs;
}

vec3 getMaterial(vec3 ro, vec3 rd, vec3 ray, float matId) {
  vec3 color;

  if (matId == 1.0) {
    color = vec3(0.0, 0.0, 1.0);
  }

  if (matId == 2.0) {
    color = vec3(1.0, 0.0, 0.0);
  }

  if (matId == 3.0) {
    color = vec3(0.0, 1.0, 0.0);
  }

  if (matId == 4.0) {
    vec3 p = fract(ray * 7.0 + u_time);
    float grid;
    grid += smoothstep(0.11, 0.1, abs(p.x));
    grid += smoothstep(0.11, 0.1, abs(p.y));
    color += grid;
  }

  if (matId == 5.0) {
    color = vec3(1.0, 0.0, 1.0);
  }

  if (matId == -1.0) {
    color = vec3(0.0, 0.0, rd.y);
  }      

  return color;
}

float scene(vec3 p, out float matId)
{
  sceneObj sceneObjs[5];
  sceneObjs = getSceneObjs(p);
  float d = 10e7; 

  for (int i = 0; i < sceneObjs.length(); i++) {
    sceneObj obj = sceneObjs[i];
    if (obj.dist < SURF_DIST) matId = obj.matId;
    d = min(d, obj.dist);
  }

  return d;
}

float scene(vec3 p) {
  float matId = -1.0;
  return scene(p, matId);
}

float trace(vec3 ro, vec3 rd, out float matId) {
  float t = 0.0;

  for (int i = 0; i < MAX_STEPS; i++) {
    if (t > FAR) break;
    vec3 p = ro + rd * t;
    float d = scene(p, matId);
    if (d < SURF_DIST) break;
    t += d;
  }

  return t;
}

vec3 getNormal(in vec3 p) {
  const vec2 e = vec2(0.001, 0);

  return normalize(vec3(
    scene(p + e.xyy) - scene(p - e.xyy), 
    scene(p + e.yxy) - scene(p - e.yxy),	
    scene(p + e.yyx) - scene(p - e.yyx)
  ));
}

vec3 render(in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / u_resolution - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 ro = vec3(0.0, 0.25, -2.5);
  vec3 rd = normalize(vec3(uv, 1.0));

  float matId = -1.0;
  float t = trace(ro, rd, matId);
  vec3 ray = ro + rd * t;

  light diffuseLight;
  diffuseLight.position = vec3(1.0, 2.0, -2.0);
  diffuseLight.direction = normalize(diffuseLight.position - ray);

  vec3 normal = getNormal(ray);
  float diffuse = max(dot(diffuseLight.direction, normal), 0.0);

  vec3 viewPos = vec3(0.5, 3.0, -7.0);
  vec3 lightDirection = normalize(diffuseLight.position - ray);
  vec3 reflectDirection = reflect(-diffuseLight.direction, normal);
  float spec = pow(max(dot(normalize(viewPos - ray), reflectDirection), 0.0), 32.0); 
  float specStrength = 0.9; 

  vec3 mat = getMaterial(ro, rd, ray, matId);
  vec3 color = mat; 

  if (matId != -1.0) {
    color = color * diffuse + spec * specStrength;
  }

  return color;
}

void main() {
  vec3 color;
  color += render(gl_FragCoord.xy + vec2(0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25, 0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25, 0.25));
  color /= 4.0;

  gl_FragColor = vec4(color, 1.0);
}
