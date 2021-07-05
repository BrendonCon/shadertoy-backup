precision mediump float;

uniform float u_time;
uniform vec2 u_resolution;

#define MAX_STEPS 386
#define SURFACE 0.00001
#define STEP_BIAS 1.0
#define FAR 100.0

const float PI = 3.14159;
const float TAU = PI * 2.0;

float sphere(vec3 p, float r)
{
  return length(p) - r;
}

float plane(vec3 p, vec3 n)
{
  return max(dot(p, n), 0.0);
}

float plane(vec3 p)
{
  return p.y;
}

float box(vec3 p, vec3 s)
{
  return length(max(abs(p) - s, 0.0));
}

vec3 toneMapUnreal(vec3 x) 
{
  return x / (x + 0.155) * 1.019;
}

mat2 rotate(float theta)
{
  float s = sin(theta);
  float c = cos(theta);
  return mat2(c, -s, s, c);
}

vec2 closest(vec2 a, vec2 b)
{
  if (a.x < b.x) return a;
  return b;
}

vec2 normalizeScreenSpace(vec2 p, vec2 resolution)
{
  vec2 uv = p / resolution - 0.5; 
  uv.x *= resolution.x / resolution.y;
  return uv;
}

#define NUM_OCTAVES 3

float rand(vec2 n) 
{ 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p)
{
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

float fbm(vec2 x) 
{
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);
  mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));

	for (int i = 0; i < NUM_OCTAVES; ++i) 
  {
		v += a * noise(x);
		x = rot * x * 2.0 + shift;
		a *= 0.5;
	}

	return v;
}

vec3 envMap(vec3 rd)
{
  vec3 c1 = vec3(0.773,0.859,0.122);
  vec3 c2 = vec3(1.000,0.161,0.537);
  float x = clamp(rd.y + 0.8, 0.0, 1.0);
  return mix(c1, c2, x);
}

vec2 edge(vec2 p)
{
  vec2 pp = abs(p);
  if (pp.x > pp.y) return vec2(float(sign(p.x)), 0);
  return vec2(0, float(sign(p.y)));
}

vec2 scene(in vec3 p)
{   
  p.y += 1.75;
  p.z -= u_time + 50.0;

  vec2 center = floor(p.xz) + 0.5;
  vec2 neighbour = center + edge(p.xz - center);

  vec3 size = vec3(0.46);
  float maxHeight = 3.5;

  float f = fbm(center * 0.25 - u_time * 0.4);
  size.y = f * maxHeight;
  float current = box(p - vec3(center.x, 0.0, center.y), size);
  float next = box(p - vec3(neighbour.x, 0.0, neighbour.y), vec3(0.46, maxHeight, 0.46));

  vec2 b;
  b.x = min(current, next);
  b.y = 2.0;

  return b;
}

float march(vec3 ro, vec3 rd)
{
  float t = 0.0;

  for (int i = 0; i < MAX_STEPS; i++)
  {
    vec2 o = scene(ro + t * rd);
    float d = o.x;
    if (abs(d) < SURFACE || abs(t) > FAR) break;
    t += d * STEP_BIAS;
  }

  return t;
}

vec3 getNormal(vec3 p)
{
  vec2 e = vec2(0.000001, 0.0);
  return normalize(vec3(
    scene(p + e.xyy).x - scene(p - e.xyy).x,
    scene(p + e.yxy).x - scene(p - e.yxy).x,
    scene(p + e.yyx).x - scene(p - e.yyx).x
  ));
}

float hardShadows(vec3 ro, vec3 rd)
{
  float t = march(ro, rd);
  if (t < FAR) return 0.5;
  return 1.0;
}

float ao(vec3 p, vec3 n)
{
  float stepSize = 0.03;
  const float maxIterations = 5.0;
  float intensity = 0.5;
  float ao = 0.0;

  for (float i = 1.0; i <= maxIterations; i++)
  {
    float dist = i * stepSize;
    vec3 p = p + dist * n;
    ao = max((dist - scene(p).x) / dist, 0.0);
  }

  return (1.0 - ao * intensity);
}

vec3 getColor(in vec3 p, vec3 n, vec3 ro, vec3 rd)
{
  vec3 color;
    
  vec3 i = p - ro;
  vec2 obj = scene(p);
  vec3 l = normalize(vec3(-1, 4, -1));

  // ambient
  vec3 ambient = vec3(0.25);

  // spec
  vec3 r = reflect(l, n);
  vec3 v = normalize(ro - p);
  float specStrength = 30.0;
  float spec = pow(max(dot(v, r), 0.0), 3.0) * specStrength;

  // diffuse
  float halfLambert = max(dot(l, n), 0.0) * 0.5 + 0.5;

  float sha = hardShadows(p + n * 0.001, l);
  float fresnel = pow(max(1.0 + dot(rd, n), 0.0), 1.0);

  vec3 objColor = vec3(0.015, 0.02, 0.03) * 0.75;

  color = objColor * (halfLambert + ambient + spec + fresnel);
  color *= vec3(ao(p, n));
  color *= sha + ambient;
  color = mix(color, envMap(-rd), 0.025);

  return color;
}

vec3 render(vec2 fragCoord)
{
  vec2 uv = normalizeScreenSpace(fragCoord, u_resolution.xy);

  vec3 ro = vec3(0.0, 0.0, 20.0);
  vec3 rd = normalize(vec3(uv, -1));

  ro.xz *= rotate(2.45);
  rd.xz *= rotate(2.45);
  ro.yz *= rotate(0.5);
  rd.yz *= rotate(0.5);

  vec3 color = envMap(rd);
  float t = march(ro, rd);
  vec3 p = ro + t * rd;

  if (t < FAR)
  {
    vec3 n = getNormal(p);
    color = getColor(p, n, ro, rd);
  }

  color = mix(color, vec3(0.000,0.667,1.000), smoothstep(0.0, -5.0, p.y));
  color = mix(color, envMap(-rd), smoothstep(0.0, -5.0, p.y));
  color = mix(color, envMap(-rd), pow(clamp(p.x / FAR, 0.0, 1.0), 2.0));

  return color;
}

void main()
{ 
  vec3 color = toneMapUnreal(render(gl_FragCoord.xy));
  color *= 1.35;
  color *= vec3(smoothstep(1.15, 0.3, length(gl_FragCoord.xy / u_resolution - 0.5)));
  gl_FragColor = vec4(color, 1.0);
}
