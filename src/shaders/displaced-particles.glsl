precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float rand(float seed) {
  return fract(sin(seed) * 1000.0);
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

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
  float t = u_time * 0.5;
  
  float ar = u_resolution.x / u_resolution.y;
  uv.x *= ar;
  
  vec2 displacementMap = vec2(noise(uv * 25.5 + t * 5.5));
  float d = displacementMap.x * 0.01;
  uv += d;

  vec2 colorMap = vec2(noise(uv * 10.1 + t * 0.015));
  vec3 vignette = vec3(1.0 - length(uv)) * 0.25;
  vec3 bgColor = vec3(0.2, 0.1, 0.3);
  vec3 col = vec3(abs(uv.y)) * 0.01 + bgColor + vignette;
  
  for (float i = 0.0; i < 100.0; i++) {
    float seed = i + 1.0;
    float x = (rand(i) - 0.5) * 3.0;
    float y = (rand(i * 100.0)- 0.5)  * 2.0;
    float ampX = rand(seed) * 0.2;
    float ampY = rand(seed) * 0.25;
    float fx = rand(seed);
    float fy = rand(i);
    float vx = cos(fx * t + cos(t * 0.5)) * ampX;
    float vy = sin(fy * t) * ampY;
    vec2 velocity = vec2(vx, vy);
    vec2 pos = vec2(x, y) + velocity;
    float d = length(uv - pos);
    float r = rand(y) * 0.035 + 0.015;
    float alpha = rand(x) * 0.85;
    float blur = rand(x) * 0.01;
    float star = (1.0 - smoothstep(r - blur, r + colorMap.x * 0.025, d));
    col += star * alpha;
  }    

  gl_FragColor = vec4(col, 1.0);
}
