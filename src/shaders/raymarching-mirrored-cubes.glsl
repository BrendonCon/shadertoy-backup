precision mediump float;

uniform vec2 u_resolution;
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
              0.0, 0.0, 1.0);	    
}

float sdfBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);    
}

vec3 opDomainRep(vec3 uv, vec3 c) {
  return mod(uv + 0.5 * c, c) - 0.5 * c;
}

float scene(vec3 p) { 
  p = opDomainRep(p, vec3(2.0, 2.0, 4.0));

  vec3 boxSize = vec3(0.5);
  mat3 boxRot = rotateY(u_time * 0.2) * rotateX(u_time * 0.5);
  float box = sdfBox(p * boxRot, boxSize);

  return min(box, 0.15);
}

#define FAR 100.0
#define SURF_DIST 0.001

float rayMarch(vec3 ro, vec3 rd) {
  float dist = 0.0;

  for (int i = 0; i < 100; i++) {
    vec3 ray = ro + rd * dist;
    dist += scene(ray);
    if (abs(dist) > FAR || dist < SURF_DIST) break;
  }

  return dist;
}

float rayMarchReflection(vec3 ro, vec3 rd) {
  float dist = 0.0;

  for (int i = 0; i < 45; i++) {
    vec3 ray = ro + rd * dist;
    dist += scene(ray);
    if (abs(dist) > FAR || dist < SURF_DIST) break;
  }

  return dist;
}

vec3 normal(vec3 p) {
  const vec2 e = vec2(0.01, 0);
  return normalize(vec3(
    scene(p + e.xyy) - scene(p - e.xyy), 
    scene(p + e.yxy) - scene(p - e.yxy),
    scene(p + e.yyx) - scene(p - e.yyx)
  ));
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;
  
  vec3 ro = vec3(0.0, 0.0, -3.0);
  vec3 rd = normalize(vec3(uv.x, uv.y, 1.0));
  
  float dist = rayMarch(ro, rd); 
  vec3 ray = ro + rd * dist;
  vec3 surfaceNormal = normal(ray);
  
  vec3 lightDirection = vec3(0.0, 2.0, 0.5);
  float diffuse = max(dot(surfaceNormal, lightDirection + ray), 0.0); 
    
  vec3 reflectedRayDirection = reflect(rd, surfaceNormal);
  dist = rayMarchReflection(ray + surfaceNormal * 0.03, reflectedRayDirection);

  vec3 reflectedRay = ray + reflectedRayDirection * dist;
  surfaceNormal = normal(reflectedRay);

  float reflection = max(dot(surfaceNormal, lightDirection - ro), 0.0);
  float spec = pow(max(dot(reflect(-lightDirection - ro, surfaceNormal), -rd), 0.0), 0.5);
  
  vec3 color = vec3(diffuse);
  color += vec3(reflection + spec) * 0.025;
  color *= vec3(0.01, 0.3 * rd.y, 1.0);
  color = sqrt(clamp(color, 0.0, 1.0));

  gl_FragColor = vec4(color, 1.0);
}
