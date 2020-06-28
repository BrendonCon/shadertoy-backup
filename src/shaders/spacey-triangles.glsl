precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

const float PI = 3.1415926535;

float polygon(vec2 position, float radius, float sides, float blur) {
  float angle = atan(position.x, position.y);
  float slice = PI * 2.0 / sides;
  float dist = length(position);
  float alpha = cos(floor(0.5 + angle / slice) * slice - angle) * dist;
  return smoothstep(radius, radius - blur, alpha);
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
  return mat2(cos(theta), -sin(theta),
              sin(theta), cos(theta));    
}

#define NUM_OCTAVES 20
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

vec4 background(in vec2 uv) {
  vec4 color;
  
  vec4 dark = vec4(23.0 / 255.0, 8.0 / 255.0, 33.0 / 255.0, 1.0) * 1.75;
  color += dark;

  vec4 highlight = vec4(177.0 / 255.0, 55.0 / 255.0, 169.0 / 255.0, 1.0);
  color += ((1.0 - length(uv)) * highlight) * 0.2;

  vec4 glow = vec4(173.0 / 255.0, 56.0 / 255.0, 120.0 / 255.0, 1.0);
  color += (smoothstep(0.65, 0.0, length(uv)) * glow) * 0.5;

  float n = noise(uv * 1000.0);
  float stars = smoothstep(0.05, 0.0, n) * fbm(uv * 80.0);
  stars *= length(uv);
  color += stars * 2.0;
  
  return color;
}

vec4 layer(in vec2 uv) {
  uv.y *= -1.0;
  
  vec2 id = floor(uv);
  vec2 guv = fract(uv) - 0.5;  
  float clouds = fbm(uv * 5.0 * rotate(u_time * 0.001));
  float tri = polygon(guv, 0.1, 3.0, 0.025);
  vec3 c1 = vec3(56.0 / 255.0, 17.0 / 255.0, 52.0 / 255.0);
  vec3 c2 = vec3(17.0 / 255.0, 6.0 / 255.0, 21.0 / 255.0);
  vec4 color = vec4(tri);
  vec4 outline = mix(color, vec4(clouds * clouds * 0.3), tri) * 3.0;
  float stars = smoothstep(0.025, 0.0, length(fract(uv * 5.0)- 0.5));
  
  return outline + stars + (clouds * clouds) * 0.6;
}

vec4 layers(in vec2 uv) {
	vec4 color;
  float t = u_time * 0.1;
  
  vec2 mouse = u_mouse.xy / u_resolution.xy - 0.5;
  uv += mouse * 0.0;
  
  for (float i = 0.0; i <= 1.0; i += 1.0 / 8.0) {
    float depth = fract(i + t);
    float scale = mix(10.0, 0.1, depth);
    float fade = depth * smoothstep(1.0, 0.99, depth);
    vec4 layer = layer(uv * scale);
    color = mix(color, max(layer * fade, color), layer.a);
  }
    
  return color * 0.5;
}

vec4 scanlines(in vec2 uv) {
  float alpha = 0.045;
  float scale = 800.0;
	return vec4(sin(uv.y * scale)) * alpha;
}

float vignette(vec2 uv) {
  return 1.0 - length(uv * 0.8);
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec4 color;
  color = background(uv); 
  color += layers(uv);
  color += scanlines(uv);
  color *= vignette(uv);
  color.a = 1.0;

  gl_FragColor = color * 1.1;
}