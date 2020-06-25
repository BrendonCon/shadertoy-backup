precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

mat3 rotateX(float theta) {
  float s = sin(theta);
  float c = cos(theta);

  return mat3(1.0, 0.0, 0.0,
              0.0, c, -s,
              0.0, s, c);
}

mat3 rotateY(float theta) {
  float s = sin(theta);
  float c = cos(theta);

  return mat3(c, 0.0, s,
              0.0, 1.0, 0.0,
              -s, 0.0, c);
}

mat3 rotateZ(float theta) {
  float s = sin(theta);
  float c = cos(theta);

  return mat3(c, -s, 0.0,
              s, c, 0.0,
              -0.0, 0.0, 1.0);	    
}

float sdfSphere(vec3 uv, vec4 sphere) {
  return length(uv - sphere.xyz) - sphere.w;
}

float sdfBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);    
}

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
  float s = sin(theta);
  float c = cos(theta);
  return mat2(c, -s, s, c);    
}

#define NUM_OCTAVES 5
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

float getDist(vec3 p) {
  vec2 mouse = u_mouse.xy / u_resolution.xy - 0.5;

  vec3 box1 = vec3(1.0);
  mat3 boxRotation1 = rotateY(1.57) * rotateZ(1.57);
  vec3 boxPosition1 = vec3(0.5, 1.5, 0.0);
  float boxDist1 = sdfBox((p - boxPosition1) * boxRotation1 * rotateY(u_time) * rotateZ(u_time), box1);

  vec3 box2 = vec3(1.0);
  mat3 boxRotation2 = mat3(0.0);
  vec3 boxPosition2 = vec3(0.5, 1.5, 0.0);
  float boxDist2 = sdfBox((p - boxPosition2) * rotateY(u_time - 1.0) * rotateZ(u_time), box2); 

  float t = u_time * 0.5;
  vec4 spherePosition = vec4(sin(t) * 5.0, 1.5, cos(t) * 1.75, 0.4);
  float sphere = sdfSphere(p, spherePosition);

  float planeDist = min(p.y, 0.5);
  float boxMult = boxDist2 * boxDist1;
  float boxDiv = boxDist2 / boxDist1;
  float boxAdd = boxDist2 + boxDist1;
  float boxSub = boxDist1 - boxDist2;
  float boxMin = min(boxDist1, boxDist2);
  float boxMax = max(boxDist1, boxDist2);
  float boxMix = mix(boxDist1, boxDist2, 0.5);
  float boxFbm = fbm(p.xz * 0.25);
  float boxFbmMix = mix(boxDist1, boxDist2 * boxFbm, boxFbm);

  float planeMat = boxFbm * step(p.y, 0.5);
  float dist = min(planeDist + planeMat, boxMax);

  return dist;
}

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.01

float rayMarch(vec3 rayOrigin, vec3 rayDirection) {
  float distOrigin = 0.0;

  for (int i = 0; i < MAX_STEPS; i++) {
    vec3 p = rayOrigin + rayDirection * distOrigin;
    float distScene = getDist(p);
    distOrigin += distScene;
    if (distOrigin > MAX_DIST || distScene < SURF_DIST) break;
  }

  return distOrigin;
}

vec3 getNormal(vec3 uv) {
  float dist = getDist(uv);
  vec2 epsilon = vec2(0.01, 0.0);

  vec3 norm = dist - vec3(
    getDist(uv - epsilon.xyy),
    getDist(uv - epsilon.yxy),
    getDist(uv - epsilon.yyx)
  );

  return normalize(norm);
}

float getSpecular(vec3 uv, vec3 viewPosition, vec3 lightPosition, vec3 normal, float strength) {
  vec3 viewDirection = normalize(viewPosition - uv);
  vec3 lightDirection = normalize(lightPosition - uv);
  vec3 reflectDirection = reflect(-lightDirection, normal);
  float spec = pow(max(dot(viewDirection, reflectDirection), 0.0), 32.0); 
  return spec * strength;
}

float getDiffuse(vec3 uv, vec3 lightPosition, vec3 normal) {
  vec3 lightDirection = normalize(lightPosition - uv);
  float diffuse = clamp(dot(normal, lightDirection), 0.0, 1.0);
  return diffuse;
}

vec3 getAmbient() {
  float ambientStrength = 0.1;
  vec3 ambientColor = vec3(1.0);
  return ambientStrength * ambientColor;
}

float getLight(vec3 p) {
  vec3 lightPosition = vec3(0.0, 3.0, -4.75);
  vec3 lightVector = normalize(lightPosition - p);
  vec3 normal = getNormal(p);

  float diffuse = getDiffuse(p, lightPosition, normal);
  float dist = rayMarch(p + normal * SURF_DIST * 2.0, lightVector);

  if (dist < length(lightPosition - p)) {
      diffuse *= 0.5;
  }

  vec3 viewPos = vec3(-1.5, 3.0, -4.75);
  float spec = getSpecular(p, viewPos, lightPosition, normal, 0.5);
  float ambient = 0.05;

  return diffuse + spec + ambient;
}

void main() {
  vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

  vec3 rayOrigin = vec3(0.5 + sin(u_time * 0.5) * 0.25, 1.3, -5.25);
  vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1.0));
  float dist = rayMarch(rayOrigin, rayDirection);

  vec3 p = rayOrigin + rayDirection * dist;
  float diffuse = getLight(p);
  float background = 1.0 - uv.y;
  vec3 color = vec3(mix(background * 0.075, diffuse, diffuse));

  gl_FragColor = vec4(color, 1.0);
}
