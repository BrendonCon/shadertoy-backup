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

float sphere(vec3 ray, float radius) {
  return length(ray) - radius;
}

float sdfBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);    
}

float scene(vec3 ray) {
  float t = u_time;
  float sphere1 = sphere(ray - vec3(-0.3, 0.6, 1.0) * rotateY(t), 0.35);
  float sphere2 = sphere(ray - vec3(0.0, -0.5, -1.5) * rotateY(-t), 0.3);
  float sphere3 = sphere(ray - vec3(0.0, 0.0, 1.0) * rotateX(t), 0.15);
  float sphere4 = sphere(ray - vec3(0.5, 0.9, -1.0) * rotateX(-t * 0.5), 0.2);

  vec3 boxSize = vec3(0.45);
  mat3 boxRot = rotateY(t * 0.2) * rotateX(t * 0.5);
  float box = sdfBox(ray * boxRot, boxSize);

  float sceneObjects = box;
  sceneObjects = min(sceneObjects, sphere1);
  sceneObjects = min(sceneObjects, sphere2);
  sceneObjects = min(sceneObjects, sphere3); 
  sceneObjects = min(sceneObjects, sphere4);

  return min(sceneObjects, 0.1);
}

float march(vec3 ro, vec3 rd) {
  float dist = 0.0;
  const float MAX_STEPS = 100.0;
  const float SURF_DIST = 0.001;
  const float FAR = 100.0;
  
  for (float i = 0.0; i < MAX_STEPS; i++) {
    vec3 ray = ro + rd * dist;
    float d = scene(ray);
    if (d < SURF_DIST || d > FAR) break;
    dist += d;
  }
  
  return dist;
}

vec3 normal(in vec3 p) {
  const vec2 e = vec2(0.02, 0);
    
  return normalize(vec3(
    scene(p + e.xyy) - scene(p - e.xyy), 
    scene(p + e.yxy) - scene(p - e.yxy),	
    scene(p + e.yyx) - scene(p - e.yyx)
  ));
}

float phong(vec3 ro, vec3 rd, vec3 ray, vec3 lightPosition) {
  float ambient = 0.01;

  vec3 lightDirection = normalize(lightPosition - ray);
  vec3 surfaceNormal = normal(ray);
  float diffuse = max(dot(surfaceNormal, lightDirection), 0.0);

  vec3 viewPosition = vec3(-1.5, 2.0, -5.0);
  vec3 viewDirection = normalize(viewPosition - ro);
  vec3 reflectDirection = reflect(lightDirection, surfaceNormal);
  float specStrength = 0.25;
  float specExp = 32.0;
  float spec = pow(max(dot(viewDirection, reflectDirection), 0.0), specExp) * specStrength;

  return ambient + diffuse + spec;
}

float shadow(vec3 ray, vec3 lightPosition) {
  vec3 lightDirection = normalize(lightPosition - ray);
  float shadowStrength = 0.75;
  vec3 surfaceNormal = normal(ray);
  float d = march(ray + surfaceNormal, lightDirection);
  
  if (d < length(lightPosition - ray)) {
    return shadowStrength;
  }

  return 1.0;
}

float reflection(vec3 ro, vec3 rd, vec3 lightDirection) {
  vec3 surfaceNormal = normal(ro);
  vec3 reflectDirection = reflect(rd, surfaceNormal);

  float d = march(ro + surfaceNormal * 0.1, reflectDirection);
  vec3 ray = ro + reflectDirection * d;
  vec3 reflectedSurfaceNormal = normal(ray);

  float diffuse = max(dot(reflectedSurfaceNormal, lightDirection - ray), 0.0);
  float spec = pow(max(dot(reflect(lightDirection - ray, -reflectedSurfaceNormal), reflectDirection), 0.0), 1.0);
  float strength = 0.065;

  return (diffuse + spec) * strength;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 ro = vec3(0.0, 0.1, 4.0);
  vec3 rd = normalize(vec3(uv.x, uv.y, -1.0));

  float d = march(ro, rd);
  vec3 lightPosition = vec3(0.0, 1.0, 2.0);
  vec3 ray = ro + rd * d;

  float phong = phong(ro, rd, ray, lightPosition);
  float shadow = shadow(ray, lightPosition);
  float reflection = reflection(ray, rd, lightPosition);
  vec3 backgroundGrad = vec3(smoothstep(0.7, 0.0, length(uv)) * 0.03);

  vec3 color = backgroundGrad;
  color += phong;
  color += reflection;

  gl_FragColor = vec4(color, 1.0);
}
