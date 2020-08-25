precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

#define SURF_DIST 0.01
#define FAR 90.0
#define MAX_STEPS 80

vec4 sphere(in vec3 p, float radius, vec3 mat) {
  return vec4(mat, length(p) - radius);
}

vec4 box(vec3 p, vec3 b, vec3 mat) {
  vec3 q = abs(p) - b;
  float d = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
  return vec4(mat, d);    
}

vec4 minObj(in vec4 a, in vec4 b) {
  return a.w < b.w ? a : b;
}

vec4 scene(in vec3 p) {
  vec4 sphere1 = sphere(p, 0.5, vec3(1.0, 0.0, 0.0));
  vec4 sphere2 = sphere(p - vec3(1.0, 0.0, 1.0), 0.5, vec3(0.0, 1.0, 0.0));
  vec4 sphere3 = sphere(p - vec3(-1.0, 0.0, 1.0), 0.5, vec3(0.0, 0.0, 1.0));

  vec4 box1 = box(p - vec3(0.0, 3.0, 0.0), vec3(3.3, 0.2, 5.0), vec3(0.0, 0.0, 1.0));
  vec4 box2 = box(p - vec3(0.0, -3.0, 0.0), vec3(3.3, 0.2, 5.0), vec3(0.0, 1.0, 0.0));
  vec4 box3 = box(p - vec3(-3.5, 0.0, 0.0), vec3(0.2, 3.0, 5.0), vec3(1.0, 0.5, 0.7));
  vec4 box4 = box(p - vec3(3.5, 0.0, 0.0), vec3(0.2, 3.0, 5.0), vec3(0.2, 0.5, 0.7));
  vec4 box5 = box(p - vec3(0.0, 0.0, 4.7), vec3(5.0, 3.0, 0.2), vec3(1.0, 1.0, 0.4));
  vec4 box6 = box(p - vec3(0.0, 0.0, -4.7), vec3(5.0, 3.0, 0.2), vec3(0.6, 0.25, 0.65));

  vec4 obj = minObj(sphere1, vec4(1.0));
  obj = minObj(obj, sphere2);
  obj = minObj(obj, sphere3);
  obj = minObj(obj, box1);
  obj = minObj(obj, box2);
  obj = minObj(obj, box3);
  obj = minObj(obj, box4);
  obj = minObj(obj, box5);
  obj = minObj(obj, box6);

  return obj;    
}

vec4 march(in vec3 ro, in vec3 rd) {
  float d = 0.0;
  vec4 t = vec4(0.0);

  for (int i = 0; i < MAX_STEPS; i++) {
    if (d > FAR) break;
    t = scene(ro + d * rd);     
    d += t.w;
    t.w = d;
    if (t.w < SURF_DIST) break;
  }

  return t;
}

vec3 getNormal(in vec3 p) {
  vec2 e = vec2(0.01, 0);

  return normalize(vec3(
    scene(p + e.xyy).w - scene(p - e.xyy).w, 
    scene(p + e.yxy).w - scene(p - e.yxy).w,	
    scene(p + e.yyx).w - scene(p - e.yyx).w
  ));
}

float getLight(in vec3 p) {
  vec3 lightPos = vec3(0.0, 3.0, 1.0);

  vec3 L = normalize(p - lightPos);
  vec3 N = getNormal(p);

  float diffuse = clamp(dot(N, -L), 0.0, 1.0);
  float diffuseIntensity = 0.3;

  float ambient = clamp(dot(N, vec3(0.0, -1.0, -1.0)), 0.0, 1.0); 
  float ambientIntensity = 0.1;

  float spec = pow(clamp(dot(-L, reflect(normalize(p), N)), 0.0, 1.0), 150.0);
  float specIntensity = 0.9;

  float fresnel = 1.0 - clamp(dot(N, normalize(-p)), 0.0, 1.0);
  float fresnelIntensity = 0.15;

  return diffuse * diffuseIntensity + 
        spec * specIntensity + 
        ambient * ambientIntensity + 
        fresnel * fresnelIntensity;   
}

vec3 getColor(in vec3 ro, in vec3 rd) {
  vec3 color = vec3(0.0);

  for (float i = 0.0; i < 5.0; i++) {
    vec4 scene = march(ro, rd);
    vec3 p = ro + scene.w * rd;

    color += scene.rgb * getLight(p);

    rd = reflect(normalize(p - ro), getNormal(p));
    ro = p + rd * 0.25;
  }

  return color;
}

mat3 rotateY(float theta) {
  float c = cos(theta);
  float s = sin(theta);

  return mat3(c, 0.0, s,
              0.0, 1.0, 0.0,
              -s, 0.0, c);
}

vec3 render(in vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 ro = vec3(0.0, 0.25, -3.25);
  vec3 rd = normalize(vec3(uv, 1.0));

  mat3 worldRot = rotateY(u_time * 0.5);
  ro *= worldRot;
  rd *= worldRot;

  return getColor(ro, rd);
}

void main() {
  vec3 color = vec3(0.0);
  color += render(gl_FragCoord.xy + vec2(0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25, 0.25));
  color += render(gl_FragCoord.xy + vec2(-0.25));
  color += render(gl_FragCoord.xy + vec2(0.25, -0.25));
  color /= 4.0;

  gl_FragColor = vec4(sqrt(color), 1.0);
}
