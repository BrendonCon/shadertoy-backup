precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float n21(vec2 uv) {
  return fract(sin(dot(uv, vec2(23.5, 7895.6))) * 451.9);
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
  float c = cos(theta);
  float s = sin(theta);
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

vec3 backgroundSky(in vec2 uv) {
  float backgroundMask = abs((1.0 - uv.y) * 0.25);
  vec3 backgroundColor = mix(vec3(0.0), vec3(0.1, 0.1, 0.8), backgroundMask);
  vec3 color = vec3(backgroundColor * 0.6);
  color += vec3(fbm(uv * 10.0)) * 0.1;
  return color;
}

vec3 stars(in vec2 uv) {
  float n = n21(uv);
  float stars = smoothstep(0.0025, 0.0015, n);
  stars *= 0.25;
  return vec3(stars);
}

vec3 stars(in vec2 uv, float alpha) {
  return stars(uv) * alpha;
}

vec3 stars(in vec2 uv, in vec2 position, float alpha) {
  return stars(uv - position, alpha);
}

vec3 smoke(in vec2 uv) {
  uv *= rotate(-0.05);
  uv.y += 0.2;
  float smokeSpeed = u_time * 0.15;
  float n = fbm(uv * 10.0 + u_time * 0.1);
  float smoke = smoothstep(-0.2, 0.2, uv.y - fbm(uv * 10.0 + smokeSpeed) * 0.125);
  smoke *= 1.0 - smoothstep(-0.2, 0.2 + n * 0.5, uv.y - fbm(uv * 10.0 - smokeSpeed) * 0.15);
  return vec3(smoke) * 0.35; 
}

vec3 filmGrain(in vec2 uv) {
  return vec3(n21(uv * 10.0 + u_time * 0.0001)) * 0.025;
}

float vignette(in vec2 uv) {
  return 1.0 - length(uv * vec2(0.75, 0.25));
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 color = vec3(0.0);
  color += backgroundSky(uv);
  color += stars(uv, 0.7);
  color += stars(uv, vec2(0.35, 0.75), 0.2);
  color += smoke(uv);
  color += filmGrain(uv);
  color *= vignette(uv);
  
  gl_FragColor = vec4(color, 1.0);
}