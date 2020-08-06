precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

mat3 rotateZ(float theta) {
  float s = sin(theta);
  float c = cos(theta);

  return mat3(c, -s, 0.0,
              s, c, 0.0,
              -0.0, 0.0, 1.0);	    
}

float sdfBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);    
}

float getDist(vec3 p) {
  vec3 box1 = vec3(3.1, 0.2, 0.2);
  float boxDist1 = sdfBox(p, box1);
  
  vec3 box2 = vec3(0.2, 3.1, 0.2);
  float boxDist2 = sdfBox(p, box2);
  
  return min(boxDist2, boxDist1);
}

vec3 domainRep(in vec3 uv, in vec3 c) {
  return mod(uv + 0.5 * c, c) - 0.5 * c;
}

#define DOMAIN_REP vec3(6.0, 6.0, 6.0)
#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.01

float rayMarch(vec3 rayOrigin, vec3 rayDirection) {
	float distOrigin = 0.0;
    
  for (int i = 0; i < MAX_STEPS; i++) {
      vec3 p = rayOrigin + rayDirection * distOrigin;
      float distScene = getDist(domainRep(p, DOMAIN_REP));
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

float getLight(vec3 p) {
  p = domainRep(p, DOMAIN_REP);

  vec3 lightPosition = vec3(0.0, 0.0, -1.75);
  vec3 lightVector = normalize(lightPosition - p);
  vec3 normal = getNormal(p);

  float diffuse = getDiffuse(p, lightPosition, normal);
  vec3 viewPos = vec3(-1.5, 3.0, -7.0);
  float spec = getSpecular(p, viewPos, lightPosition, normal, 0.25);

  return diffuse + spec;
}

void main() {
  vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
  vec2 mouse = (u_mouse.xy / u_resolution.xy - 0.5) * 5.0;
  
  float cameraX = sin(u_time * 0.01) * 10.0 - mouse.x;
  float cameraY = sin(u_time * 0.01) * 10.0 - mouse.y;
  float cameraZ = u_time * 5.0;
  
  vec3 rayOrigin = vec3(cameraX, cameraY, 4.0 + cameraZ);
  vec3 rayDirection = normalize(vec3(uv.x, uv.y - 0.1, 1.0));
  
  rayOrigin *= rotateZ(u_time * 0.25);
  rayDirection *= rotateZ(u_time * 0.25);
  
  float dist = rayMarch(rayOrigin, rayDirection);
  vec3 rayPosition = rayOrigin + rayDirection * dist;
  float light = getLight(rayPosition);
  vec3 color = vec3(light);
  
  gl_FragColor = vec4(color, 1.0);
}
