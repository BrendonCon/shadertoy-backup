precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float hash(vec2 p) { 
  return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
}

float noise(vec2 x) {
  vec2 i = floor(x);
  vec2 f = fract(x);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
    
  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float voronoi(in vec2 p) {
  vec2 n = floor(p);
  vec2 f = fract(p);
  float md = 1.0;
  vec2 m = vec2(0.0);

  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      vec2 g = vec2(i, j);
      vec2 o = vec2(hash(n + g));

      o = 0.5 + 0.5 * sin(u_time + 5.0 * o);

      vec2 r = g + o - f;
      float d = dot(r, r);

      if (d < md) {
        md = d;
        m = n + g + o;
      }
    }
  }
  
  return max(1.0 - md, 0.1);
}

#define BRIGHTNESS 0.55
void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float ar = u_resolution.x / u_resolution.y;
  float scale = 0.75;
  float t = u_time * 0.5;
  
  uv.x *= ar;
  uv *= scale;
  uv -= t * 0.02;
  
  // NOISE
  float nScale = 0.25;
  float nTime = t * 0.2;
  float maxDisplacement = 0.05;
  float n = noise(uv * nScale + nTime);
  float d = n * maxDisplacement;
  uv += d;
  
  // VORONOI LAYERS
  float v1 = voronoi(uv * vec2(5.0) + vec2(t));
  float v2 = voronoi(uv * 5.5 + vec2(-t));
  float v3 = voronoi(uv * 6.0 + vec2(-t, t * 1.25));
  float v4 = voronoi(uv * 6.5 + vec2(t, -t * 0.75));
  
  // BLEND LAYERS
  float v = mix(v1, v2, 0.5);
  v = mix(v, v3, 0.5);
  v = mix(v, v4, 0.5);
  
  // COLOR BLEND
  vec3 col = 1.0 - vec3(smoothstep(0.25, 0.95, v));
  vec3 bg = vec3(0.0, 106.0 / 255.0, 163.0 / 255.0);
  
  vec3 composite = bg + col * BRIGHTNESS;
  
  gl_FragColor = vec4(composite, 1.0);
}