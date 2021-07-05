precision mediump float;

#define MAX_STEPS 100
#define SURFACE 0.00001
#define STEP_BIAS 1.0
#define FAR 5.0

#define MAX_BOUNCES 3
#define EXPOSURE 1.1
#define EPSILON 0.0001

const float PI = 3.14159;
const float TAU = PI * 2.0;

uniform float u_time;
uniform vec2 u_resolution;

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

float capsule(vec3 p, vec3 a, vec3 b, float radius)
{
  vec3 ap = p - a;
  vec3 ab = b - a;

  float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
  vec3 c = a + t * ab;

  return length(p - c) - radius;
}

float torus(vec3 p, float outerRadius, float innerRadius)
{
  return length(vec2(length(p.xz), p.y) - innerRadius) - outerRadius;
}

float cylinder(vec3 p, vec3 a, vec3 b, float radius)
{    
  vec3 ab = b - a;
  vec3 ap = p - a;

  float t = dot(ap, ab) / dot(ab, ab);
  vec3 c = a + t * ab;

  float x = length(p - c) - radius;
  float y = (abs(t - 0.5) - 0.5) * length(ab);
  float e = length(max(vec2(x, y), 0.0));
  float i = min(max(x, y), 0.0);

  return e + i;
}

float opUnion(float a, float b)
{
  return min(a, b);
}

float opSubtract(float a, float b)
{
  return max(a, -b);
}

float opIntersect(float a, float b)
{
  return max(a, b);
}

vec3 opSymX(vec3 p)
{
  p.x = abs(p.x);
  return p;
}

vec3 opSymY(vec3 p)
{
  p.y = abs(p.y);
  return p;
}

vec3 opSymZ(vec3 p)
{
  p.z = abs(p.z);
  return p;
}

vec3 opSymXYZ(vec3 p)
{
  p = abs(p);
  return p;
}

vec3 toneMapUnreal(vec3 x) 
{
  return x / (x + 0.155) * 1.019;
}

float hash11(float x)
{
  return fract(sin(x * 345.1) * 987.6);
}

float hash21(vec2 a)
{
  vec2 b = vec2(12.34, 24.87);
  return fract(sin(dot(a, b)) * 456.7);
}

// =============== MATH =============

mat2 rotate(float theta)
{
  float s = sin(theta);
  float c = cos(theta);
  return mat2(c, -s, s, c);
}

// =============== UTILITY =============

vec3 gammaCorrect(vec3 color)
{
  return pow(color, vec3(0.4545));
}

float rect(vec2 p, vec2 s)
{
  vec2 hs = s * 0.5;
  float w = smoothstep(hs.x, hs.x * 0.9, abs(p.x));
  float h = smoothstep(hs.y, hs.y * 0.9, abs(p.y));
  return w * h;
}

float circle(vec2 p, float radius)
{
  return smoothstep(radius, radius * 0.99, length(p));
}

vec2 closest(vec2 a, vec2 b)
{
  if (a.x < b.x) return a;
  return b;
}

float checkerPattern(in vec3 p)
{
  p = floor(p);
  return mod(p.x + p.z, 2.0);
}

vec2 normalizeScreenSpace(vec2 p, vec2 resolution)
{
  vec2 uv = p / resolution - 0.5; 
  uv.x *= resolution.x / resolution.y;
  return uv;
}

float rand(vec2 n) 
{ 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

#define NUM_OCTAVES 2

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p)
{
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

float fbm(vec3 x) 
{
	float v = 0.0;
	float a = 0.5;
	vec3 shift = vec3(100);

	for (int i = 0; i < NUM_OCTAVES; ++i) 
  {
		v += a * noise(x);
		x = x * 2.0 + shift;
		a *= 0.5;
	}

	return v;
}

vec3 glow;

vec3 envMap(in vec3 rd)
{
  vec3 color = vec3(0.231,0.231,0.231);
  return color;
}

vec2 getNotches(in vec3 p)
{
  vec2 n;
  n.x = cylinder(abs(p) - vec3(0.1, 0.4, 0.1), vec3(0, 0.02, 0), vec3(0, -0.02, 0), 0.03);
  n.y = 3.0;
  return n;
}

vec2 getGlowingLines(in vec3 p)
{    
  float d = cylinder(abs(p) - vec3(0.1, 0.0, 0.1), vec3(0, 0.4, 0), vec3(0, -0.4, 0), 0.007);

  vec2 gl;
  gl.x = d;
  gl.y = 2.0;

  return gl;
}

vec2 getNotchBase(in vec3 p)
{
  vec2 b;

  b.x = cylinder(abs(p) - vec3(0.1, 0.425, 0.1), vec3(0, 1.0, 0), vec3(0, -0.01, 0), 0.075);
  b.y = 4.0;

  return b;
}

vec2 getPipe(in vec3 p)
{
  vec2 pipe;

  float c1 = cylinder(abs(p) - vec3(0, 0.535, 0.0), vec3(0, 1.5, 0), vec3(0, -0.01, 0), 0.35);
  float c2 = cylinder(abs(p) - vec3(0, 0.535, 0.0), vec3(0, 1.6, 0), vec3(0, -0.02, 0), 0.33);

  pipe.x = opSubtract(c1, c2);
  pipe.x -= sin(p.y * 200.0) * 0.0015;
  pipe.y = 6.0;

  return pipe;
}

vec2 getBase(in vec3 p)
{
  vec2 base;

  base.x = cylinder(abs(p) - vec3(0, 0.45, 0), vec3(0, 0.01, 0), vec3(0, -0.01, 0), 0.325);
  base.y = 5.0;

  return base;
}

vec2 getPipeTrim(in vec3 p)
{
  float c1 = cylinder(abs(p) - vec3(0, 0.675, 0.0), vec3(0, 0.05, 0), vec3(0, -0.01, 0), 0.35);
  float c2 = cylinder(abs(p) - vec3(0, 0.535, 0.0), vec3(0, 0.1, 0), vec3(0, -0.02, 0), 0.33);

  vec2 trim;
  trim.x = opSubtract(c1, c2);
  trim.y = 7.0;

  return trim;
}

vec2 getPipeRim(in vec3 p)
{
  float c1 = cylinder(abs(p) - vec3(0, 0.535, 0.0), vec3(0, 0.075, 0), vec3(0, -0.01, 0), 0.4);
  float c2 = cylinder(abs(p) - vec3(0, 0.535, 0.0), vec3(0, 0.1, 0), vec3(0, -0.02, 0), 0.33);

  vec2 rim;
  rim.x = opSubtract(c1, c2);
  rim.y = 8.0;

  return rim;
}

vec2 getPipeRim2(in vec3 p)
{
  float c1 = cylinder(abs(p) - vec3(0, 0.628, 0.0), vec3(0, 0.05, 0), vec3(0, -0.01, 0), 0.38);
  float c2 = cylinder(abs(p) - vec3(0, 0.535, 0.0), vec3(0, 0.1, 0), vec3(0, -0.02, 0), 0.33);

  vec2 rim;
  rim.x = opSubtract(c1, c2);
  rim.y = 5.0;

  return rim;
}

vec2 scene(in vec3 p)
{   
  p.xy *= rotate(0.1);
  p.xz *= rotate(-u_time);
  p.y -= sin(u_time * 3.0 + sign(p.x) + sign(p.z)) * 0.25;

  p = abs(p) - vec3(0.75, 0, 0.75);
  p.xz *= rotate(-u_time * 5.0);

  vec2 gl = getGlowingLines(p);

  vec2 n = getNotches(p);
  vec2 nb = getNotchBase(p);
  vec2 base = getBase(p);
  vec2 pipe = getPipe(p);
  vec2 rim = getPipeRim(p);
  vec2 rim2 = getPipeRim2(p);
  vec2 trim = getPipeTrim(p);

  vec2 obj;
  obj = closest(gl, n);
  obj = closest(obj, nb);
  obj = closest(obj, base);
  obj = closest(obj, pipe);
  obj = closest(obj, rim);
  obj = closest(obj, rim2);
  obj = closest(obj, trim);

  return obj;
}

vec2 scene(in vec3 p, bool withGlow)
{   
  p.xy *= rotate(0.1);
  p.xz *= rotate(-u_time);
  p.y -= sin(u_time * 3.0 + sign(p.x) + sign(p.z)) * 0.25;
  p = abs(p) - vec3(0.75, 0, 0.75);
  p.xz *= rotate(-u_time * 5.0);

  vec2 gl = getGlowingLines(p);
  glow += 0.02 / ((gl.x * gl.x)) * 0.005;

  vec2 n = getNotches(p);
  vec2 nb = getNotchBase(p);
  vec2 base = getBase(p);
  vec2 pipe = getPipe(p);
  vec2 rim = getPipeRim(p);
  vec2 rim2 = getPipeRim2(p);
  vec2 trim = getPipeTrim(p);

  vec2 obj;
  obj = closest(gl, n);
  obj = closest(obj, nb);
  obj = closest(obj, base);
  obj = closest(obj, pipe);
  obj = closest(obj, rim);
  obj = closest(obj, rim2);
  obj = closest(obj, trim);

  return obj;
}

float march(vec3 ro, vec3 rd)
{
  float t = 0.0;

  for (int i = 0; i < MAX_STEPS; i++)
  {
    if (abs(t) > FAR) break;
    vec2 o = scene(ro + t * rd);
    float d = o.x;
    if (abs(d) < SURFACE) break;
    t += d * STEP_BIAS;
  }

  return t;
}

float march(vec3 ro, vec3 rd, bool withGlow)
{
  float t = 0.0;

  for (int i = 0; i < MAX_STEPS; i++)
  {
    if (abs(t) > FAR) break;
    vec2 o = scene(ro + t * rd, true);
    float d = o.x;
    if (abs(d) < SURFACE) break;
    t += d * STEP_BIAS;
  }

  return t;
}

vec3 getNormal(vec3 p)
{
  vec2 e = vec2(EPSILON, 0.0);
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
  float stepSize = 0.05;
  const float maxIterations = 10.0;
  float intensity = 1.0;
  float ao = 0.0;

  for (float i = 1.0; i <= maxIterations; i++)
  {
    float dist = i * stepSize;
    vec3 p = p + dist * n;
    ao = max((dist - scene(p).x) / dist, 0.0);
  }

  return (1.0 - ao * intensity);
}

vec3 getObjectColor(float id, vec3 p, vec3 n, vec3 ro, vec3 rd)
{
  if (id == 1.0)
  {
    vec3 color = vec3(fbm(p * 0.5));
    color = mix(color, vec3(fbm(p.yyy * 2.0)), 0.3);
    return color;
  }

  if (id == 2.0) return vec3(1.0);

  if (id == 3.0)
  {
    return vec3(1.0);
  }

  if (id == 4.0)
  {
    return vec3(0.051,0.518,0.749) * 1.1;
  }

  if (id == 5.0)
  {
    return vec3(0.6);
  }

  if (id == 6.0)
  {
    return vec3(0.25);
  }

  if (id == 7.0)
  {
    return vec3(1.000,0.835,0.000);
  }

  if (id == 8.0)
  {
    return vec3(0.075);    
  }

  if (id == 9.0)
  {
    return vec3(0);    
  }

  if (id == 10.0)
  {
    return vec3(1000, 0, 0);
  }
}

vec3 getColor(in vec3 p, vec3 n, vec3 ro, vec3 rd)
{
  vec3 color;

  vec3 i = p - ro;
  vec2 obj = scene(p);
  vec3 l = normalize(vec3(0.0, 1.0, 2));

  // ambient
  vec3 ambient = vec3(0.01);

  // spec
  vec3 r = reflect(l, n);
  vec3 v = normalize(ro - p);
  float specStrength = 2.0;
  float spec = pow(max(dot(rd, r), 0.0), 1.0) * specStrength;

  // diffuse
  float halfLambert = max(dot(l, n), 0.0) * 0.5 + 0.5;

  float sha = hardShadows(p + n * 0.0001, l);
  float fresnel = pow(max(1.0 + dot(rd, n), 0.0), 5.0);

  vec3 objColor = getObjectColor(obj.y, p, n, ro, rd);
  color = objColor * (halfLambert + ambient + spec);
  color *= vec3(ao(p, n));
  color *= sha * objColor;
  color = mix(color, envMap(rd), 0.125);

  return color;
}

vec3 render(vec2 fragCoord)
{
  vec2 uv = normalizeScreenSpace(fragCoord, u_resolution.xy);
  vec3 ro = vec3(0.0, 0.0, 2.5);
  vec3 rd = normalize(vec3(uv, -1));
  vec3 ord = rd;

  vec3 bg = envMap(rd);
  vec3 color = bg;
  float t = march(ro, rd, true);
  vec3 p = ro + t * rd;

  if (t < FAR)
  {
    vec3 n = getNormal(p);
    color = getColor(p, n, ro, rd);

    for (int i = 0; i < MAX_BOUNCES; i++)
    {
      float t = march(ro, rd);

      if (t < FAR)
      {
        p = ro + t * rd;
        n = getNormal(p);
        color += getColor(p, n, ro, rd) * 0.35;
        ro = p + n;
        rd = reflect(rd, n);
      }
    }
  }

  color += glow * vec3(0.000, 0.882, 1.000);
  color = mix(bg, color, vec3(smoothstep(0.5, 0.4, abs(ord.y))));

  return color;
}

void main()
{
  vec3 color = render(gl_FragCoord.xy);
  color = toneMapUnreal(color);
  color *= vec3(smoothstep(1.1, 0.25, length(gl_FragCoord.xy / u_resolution - 0.5)));
  color *= EXPOSURE;
  gl_FragColor = vec4(color, 1.0);
}