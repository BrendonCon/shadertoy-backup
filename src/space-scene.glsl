precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float hash(vec2 p) { 
  return fract(1e3 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
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

float fbm(in vec2 uv) {
  float v = 0.0;
  float a = 0.5;
  vec2 shift = vec2(100.0);
  mat2 rot = rotate(0.5);
  
  for (int i = 0; i < 8; ++i) {
    v += a * noise(uv);
    uv = rot * uv * 2.0 + shift;
    a *= 0.5;
  }
  
  return v;
}

vec4 stars(in vec2 uv) {
  vec4 stars = vec4(noise(uv * 500.0));
  stars = smoothstep(0.015, 0.01, stars) * 0.175;
  return stars;
}

vec4 vignette(in vec2 uv) {
  vec4 vignette = vec4(1.0 - smoothstep(0.0, 0.5, length(uv * vec2(0.2))));
  vignette = smoothstep(0.0, 0.5, vignette);
  return vignette;
}

vec4 glow(in vec2 uv) {
  vec4 glow = vec4(1.0 - smoothstep(0.0, 1.0 - fbm(uv * 15.0) * 0.1, length(uv * vec2(0.3, 1.05) - vec2(0.2, 0.0))));
  glow *= fbm(uv * 3.0);
  glow *= glow;
  return glow;
}

vec4 gasClouds(in vec2 uv) {
  uv.x -= 0.5;

  vec4 gasCloud1 = vec4(length(uv * rotate(4.2) * vec2(0.5, 0.12)));
  gasCloud1 = 1.0 - smoothstep(0.1, 0.6 + fbm(uv * 0.5), gasCloud1);
  gasCloud1 *= 0.0125;
  gasCloud1 *= fbm(uv * 0.5);
  gasCloud1 *= vec4(0.0, 0.0, 12.0, 1.0);
  
  vec4 gasCloud2 = vec4(length(uv * rotate(4.5) * vec2(0.5, 0.12)));
  gasCloud2 = 1.0 - smoothstep(0.0, 0.6 + fbm(uv * 0.5), gasCloud2);
  gasCloud2 *= 0.1;
  gasCloud2 *= fbm(uv * 0.5);
  
  vec4 backCloud = 1.0 - smoothstep(0.0, 0.2 + fbm(uv), vec4(length(uv * vec2(0.15, 1.0))));
  backCloud *= 0.1;
  backCloud *= vec4(0.3, 0.6, 0.6, 1.0);
  backCloud *= fbm(uv);
  
  vec4 midCloud = 1.0 - smoothstep(0.0, 0.01 + fbm(uv * 5.0), vec4(length(uv * vec2(0.15, 1.0))));
  midCloud *= 0.1;
  midCloud *= vec4(0.2, 0.6, 0.9, 1.0);
  midCloud *= fbm(uv * 5.0);
  
  vec4 foreCloud = 1.0 - smoothstep(0.0, 10.0 + fbm(uv * 5.5), vec4(length(uv * vec2(0.25, 15.0))));
  foreCloud *= 0.2;
  foreCloud *= vec4(1.1, 0.15, 0.6, 1.0);
  foreCloud *= fbm(uv * 3.5);

  return gasCloud2 + gasCloud1 + backCloud + midCloud + foreCloud;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy * 2.0 - 1.0;
  float ar = u_resolution.x / u_resolution.y;
  
  uv.x *= ar; 

  vec4 stars = stars(uv);
  vec4 gasClouds = gasClouds(uv);
  vec4 glow = glow(uv);
  vec4 vignette = vignette(uv);

  vec4 color = vec4(vec3(0.0), 1.0);
  float brightness = 1.4;
  color += stars + gasClouds + glow;
  color = color * color * color + color * brightness;
  color.rgb *= vignette.rgb;

  gl_FragColor = color;
}