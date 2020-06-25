precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

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
  return mat2(cos(theta), -sin(theta),
              sin(theta), cos(theta));    
}

#define NUM_OCTAVES 10
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

float flame(in vec2 uv, float t) {
  vec2 p = uv * 0.5;
  
  p.x *= 7.0;
  p.x += sin(uv.y * 50.0 - t * 10.0) * 0.0075;
  p.x += sin(uv.y * 20.0 - t * 10.0) * 0.00075;
  
  p.y += 0.1;
  p.y += abs(sin(uv.x * 8.0)) * max(p.y, 0.0) * 2.0;
  p.y += abs(fbm(p * 20.0 - vec2(0.0, t * 10.0))) * max(p.y, -0.005);
  p.y -= min(p.y, 0.0) * 8.0;
  
  float dist = length(p);
  float flame = 0.003 / pow(dist, 4.0);
  float glow = smoothstep(0.5, 0.3, length(uv)) * 0.025;
  
  return flame + glow;
}

vec3 flames(in vec2 uv, float time) {
  vec3 flames1 = flame(uv, time) * vec3(0.8, 0.3, 0.1);
  vec3 flames2 = flame(uv - vec2(0.3, 0.0), time) * vec3(0.3, 0.3, 0.1);
  vec3 flames3 = flame(uv + vec2(0.3, 0.0), time + 0.1) * vec3(0.1, 0.3, 0.1);
  vec3 flames4 = flame(uv + vec2(0.6, 0.0), time + 0.2) * vec3(0.1, 0.3, 0.4);
  vec3 flames5 = flame(uv - vec2(0.6, 0.0), time + 0.3) * vec3(0.3, 0.2, 0.8);

  return flames1 + flames2 + flames3 + flames4 + flames5;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;
  
  uv *= 1.125;
  uv.y += 0.05;
  
  float time = u_time;
  vec3 color = flames(uv, time);

  gl_FragColor = vec4(color, 1.0);
}
