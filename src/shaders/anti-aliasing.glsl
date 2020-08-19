precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float sphere(vec3 p, float radius) {
  return length(p) - radius;
}

float box(vec3 p, vec3 b)  {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);    
}

float torus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz) - t.x, p.y);
  return length(q) - t.y;
}

mat3 rotateX(float theta) {
  float c = cos(theta);
  float s = sin(theta);

  return mat3(1.0, 0.0, 0.0,
              0.0, c, -s,
              0.0, s, c);
}

mat3 rotateY(float theta) {
  float c = cos(theta);
  float s = sin(theta);

  return mat3(c, 0.0, s,
              0.0, 1.0, 0.0,
              -s, 0.0, c);
}

float map(in vec3 p) {
  vec3 spherePos = vec3(0.4, 0.0, 0.0);
  float sphere = sphere(p - spherePos, 0.125);

  mat3 boxRot = rotateX(0.4 + u_time) * rotateY(0.75 + u_time);
  float box = box(p * boxRot, vec3(0.1));

  mat3 torusRot = rotateX(0.8 + u_time);
  vec3 torusPos = vec3(0.4, 0.0, 0.0);
  float torus = torus(p * torusRot + torusPos, vec2(0.1, 0.05));

  float scene = min(sphere, box);
  scene = min(scene, torus);

  return min(scene, 0.5);
}

vec3 getNormal(in vec3 p) {
	vec2 e = vec2(0.01, 0);

	return normalize(vec3(
    map(p + e.xyy) - map(p - e.xyy), 
    map(p + e.yxy) - map(p - e.yxy),	
    map(p + e.yyx) - map(p - e.yyx)
  ));
}

#define MAX_STEPS 100.0
#define FAR 100.0
#define SURF_DIST 0.01

float march(vec3 ro, vec3 rd) {
  float dist = 0.0;    
    
  for (float i = 0.0; i < MAX_STEPS; i++) {
    if (dist > FAR) break;
    vec3 p = ro + rd * dist;
    float d = map(p);
    dist += d;
    if (d < SURF_DIST) break;
  }

  return dist;
}

vec3 render(in vec2 fragCoord) {
  vec2 uv = fragCoord.xy / u_resolution - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 ro = vec3(0.0, 0.0, -1.0);
  vec3 rd = normalize(vec3(uv.x, uv.y, 1.0));
  
  mat3 worldRot = rotateY(sin(u_time * 0.5) * 0.35);
  ro *= worldRot;
  rd *= worldRot;

  float dist = march(ro, rd);
  vec3 ray = ro + rd * dist;

  vec3 lightPos = vec3(0.8, 3.2, -0.9);
  vec3 N = getNormal(ray);
  vec3 L = normalize(lightPos - ray);
  float lambert = max(dot(L, N), 0.0); 
  float diffuseStrength = 0.9;
  vec3 diffuseColor = vec3(0.749, 0.537, 0.321);

  vec3 R = reflect(-L, N);
  vec3 V = normalize(-rd - ray);    
  float shininess = 80.0;
  float specStrength = 1.0;
  float spec = pow(max(dot(R, V), 0.0), shininess);
  vec3 specColor = vec3(1.0);

  vec3 ambientColor = vec3(0.8, 0.372, 0.0);
  float ambientStrength = 1.0;

  vec3 bounceColor = vec3(0.0, 0.0, 1.0);
  vec3 bouncePosition = vec3(0.0, -0.4, 0.0);
  float bounceStrength = 0.2;
  float bounce = max(dot(normalize(bouncePosition - ray), N), 0.0);

  vec3 color = (ambientStrength * ambientColor) +
              (diffuseStrength * lambert * diffuseColor) +
              (bounceStrength * bounce * bounceColor) +
              (specStrength * spec * specColor);

  if (ray.z > 5.0) color = vec3(0.0, 0.513, 0.701);    

  return color;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 color = vec3(0.0);
  vec3 naa = render(gl_FragCoord.xy);

  vec3 aa = vec3(0.0);
  aa += render(gl_FragCoord.xy + vec2(0.25, 0.25));
  aa += render(gl_FragCoord.xy + vec2(-0.25, 0.25));
  aa += render(gl_FragCoord.xy + vec2(0.25, -0.25));
  aa += render(gl_FragCoord.xy + vec2(-0.25, -0.25));
  aa /= 4.0;

  float line = smoothstep(0.005, 0.0035, abs(uv.x)); 
  color = mix(naa, aa, step(uv.x, 0.0));
  color = mix(color, line * vec3(1.0, 0.0, 0.0), line);

  gl_FragColor = vec4(sqrt(color), 1.0);
}
