precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

mat2 rotate(float theta) {
  return mat2(cos(theta), -sin(theta),
              sin(theta), cos(theta));    
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

vec4 background(in vec2 uv) {
  vec2 position = vec2(-0.5, 0.4);
  uv -= position;
  
  float scale = 0.6;
  uv *= scale;
  
  float dist = length(uv);
  float ramp = smoothstep(0.0, 1.0, dist);
  
  vec4 red = vec4(1.0, 0.301, 0.301, 1.0);
  vec4 darkRed = vec4(100.0 / 255.0, 0.0, 0.0, 1.0);
  vec4 color = mix(red, darkRed, ramp);
  
  return color;
}    

vec4 rect(in vec2 uv, float width, float height, float alpha) {
  float mask = smoothstep(width, 0.0, abs(uv.x)) * smoothstep(height, height * 0.99, abs(uv.y));
  return vec4(mask * alpha);
}

vec4 rect(in vec2 uv, float width, float height, float alpha, vec4 color) {
  vec4 mask = rect(uv, width, height, alpha);
  return mask * color;
}

vec4 lines(in vec2 uv, float t) {
  vec2 scale = vec2(50.0, 1.0);
  float f = fbm(uv * rotate(-3.14 * 0.26) * scale + t);
  f = smoothstep(0.0, 0.3, f);
  f = pow(f, 200.0);

  vec4 line = rect(uv * 0.5 * rotate(-3.14 * 0.26), 1.2, 1.2, 1.0);
  line *= vec4(1.0 - f);

  return line;    
}

#define yellow vec4(1.0, 1.0, 0.0, 1.0)
void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;
    
  float speed = 4.0;
  float t = u_time * speed;
  vec4 color = vec4(background(uv));
  
  vec4 light = rect(uv * rotate(-3.14 * 0.26), 0.75, 1.2, 0.5, yellow);
  color += light;
  
  vec4 l3 = lines(uv * 0.75 + vec2(0.3), t);
  color = mix(color, l3 * 0.1, l3.a * 0.1);

  vec4 l2 = lines(uv * 1.0 + vec2(0.3), t);
  color = mix(color, l2 * 0.25, l2.a * 0.2);

  vec4 l1 = lines(uv * 0.75, t);
  color = mix(color, l1, l1.a * 0.75);

  gl_FragColor = color * 1.1;
}