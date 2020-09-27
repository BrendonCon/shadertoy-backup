precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec3 glow = vec3(0.0);

float mod289(float x) { 
  return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec4 mod289(vec4 x) { 
  return x - floor(x * (1.0 / 289.0)) * 289.0; 
}

vec4 perm(vec4 x) { 
  return mod289(((x * 34.0) + 1.0) * x); 
}

float noise(vec3 p) {
  vec3 a = floor(p);
  vec3 d = p - a;
  d = d * d * (3.0 - 2.0 * d);

  vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
  vec4 k1 = perm(b.xyxy);
  vec4 k2 = perm(k1.xyxy + b.zzww);

  vec4 c = k2 + a.zzzz;
  vec4 k3 = perm(c);
  vec4 k4 = perm(c + 1.0);

  vec4 o1 = fract(k3 * (1.0 / 41.0));
  vec4 o2 = fract(k4 * (1.0 / 41.0));

  vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
  vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

  return o4.y * d.y + o4.x * (1.0 - d.y);
}

float sphere(vec3 p, float radius) {
	return length(p) - radius;    
}

float box(vec3 p, vec3 size) {
  vec3 q = abs(p) - size;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float map(vec3 p) {   
  vec3 u = mod(p, 2.0) - 1.0;
  float s = sphere(u - vec3(0.0), 0.5);
  
  vec3 id = floor(abs(p) / 2.0) - 0.5;
  float n = noise(id);

  vec3 color;
  color.r = fract(n * 6.5);
  color.g = fract(n * 2.0);
  color.b = fract(n * 20.0);
  
  glow += (max(1.0 - s, 0.0) * 0.015) * color;
    
  return s;
}

struct intersection {
  bool isHit;
  vec3 n;
  vec3 r;
  vec3 p;
  int steps;
  float t;
};
    
mat3 rotateY(float theta) {
  float s = sin(theta);
  float c = cos(theta);
  return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

#define MAX_STEPS 256
#define NEAR 0.0025
#define FAR 20.0
#define BIAS 0.5

intersection intersect(vec3 ro, vec3 rd) {
  intersection i;

  for (int j = 0; j < MAX_STEPS; j++) {
    if (i.t > FAR) break;

    vec3 p = ro + rd * i.t;
    float d = map(p);

    if (d < NEAR) {
      i.isHit = true;
      i.p = p;
      i.steps = j;
      break;   
    }

    i.t += d * BIAS;
  }

  return i;
}

vec3 render(vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  float t = u_time;

  vec3 ro = vec3(0, 0.75 + 0.75 * sin(t) + 0.5, 10);
  vec3 rd = normalize(vec3(uv, -1));

  mat3 rot = rotateY(t * 0.1);
  ro *= rot;
  rd *= rot;

  intersection i = intersect(ro, rd);
  vec3 color = vec3(glow / 4.0);

  return color;
}

void main() {
  vec3 color;
  color += render(gl_FragCoord.xy + vec2(0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25, 0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25));
  color += render(gl_FragCoord.xy + vec2(0.25, -0.25));
  color /= 4.0;

  gl_FragColor = vec4(color, 1.0);
}