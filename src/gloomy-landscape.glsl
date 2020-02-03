precision highp float;

uniform float u_time;
uniform vec2 u_mouse;
uniform vec2 u_resolution;

vec4 landscape(in vec2 uv) {
  float y = uv.y + sin(uv.x * 0.423) + sin(uv.x) * 0.3;
	float landscape = step(y, 0.0);  
  return vec4(landscape);
}

float n21(vec2 uv) {
  return fract(sin(dot(uv, vec2(123.45, 7895.3))) * 79854.34);    
}

float n11(float seed) {
  return fract(sin(seed * 345.21) * 8954.74);    
}

mat2 rotate(float theta) {
  return mat2(cos(theta), -sin(theta),
              sin(theta), cos(theta));
}

float square(in vec2 uv, float width, float height) {
  float halfWidth = width * 0.5;
  float halfHeight = height * 0.5;
  
  float c = smoothstep(halfWidth, halfWidth * 0.95, abs(uv.x));
  c *= smoothstep(halfHeight, halfHeight * 0.95, abs(uv.y));
  
  return c;
}

vec4 rainDrop(in vec2 uv, float width, float height) {
  float halfWidth = width * 0.5;
  float halfHeight = height * 0.5;
  
  vec2 id = floor(uv);
  float n = n21(uv);
  float c = square(uv, width, height);
  
  return vec4(c);
}

vec4 rain(in vec2 uv) {
  vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
  vec2 id = floor(uv);
  float n = n11(id.x);
  
  uv.y += n;
  id = floor(uv);

  float n1 = n21(id);
  vec2 guv = fract(uv) - 0.5;
  vec4 r = rainDrop(guv, 0.025,  0.5);    
  float maxAlpha = 0.5;
  float alpha = n1 * maxAlpha;
  float visible = step(alpha, 0.2);
    
  color = r * alpha * visible;
  
  return color;
}

vec4 rainLayers(in vec2 uv) {
  vec4 color = vec4(0.0);
  float scale = 8.0;
  float speed = 12.0;
  
  uv *= scale;
  
  float t = u_time * speed;

  for (float i = 0.0; i < 1.0; i += 1.0 / 5.0) {
    float scale = mix(0.75, 4.0, i);
    float offsetX = mix(-4.0, 4.0, i);
    float angle = mix(0.1, -0.05, i);
    vec4 r = rain(uv * scale * rotate(angle) + i + vec2(offsetX + i + t * 0.025 * i, t + i));
    color += r * (1.0 - i);
  }
  
  return color;    
}

vec4 rainSystem(vec2 uv, float t) {
  vec4 rain = rainLayers(uv + vec2(t * 0.1, 0.0));
  return rain * 0.7;
}

vec4 vignette(vec2 uv, vec4 color) {
  float v = length(uv);
  vec4 vignette = vec4(vec3(1.0 - v), v);
  color *= vignette;
  color.a = 1.0;
  return color;
}

vec4 filmGrain(vec2 uv) {
  float n = fract(sin(dot(uv, vec2(12.34, 97.5)) * 234.12) * 546.3 + u_time);
  return vec4(n * 0.035);
}

vec4 landscapeLayers(vec2 uv, float t) {
  vec2 mouse = u_mouse.xy / u_resolution.xy - 0.5;
  vec3 skyGradient = vec3(1.0 - uv.y - 0.4) * 1.8;
  vec4 color = vec4(skyGradient, 1.0);
  
  for (float i = 0.0; i < 1.0; i += 1.0 / 10.0) {
    float n = fract(sin(i * 234.12) * 5463.3) * 2.0 - 1.0;
    vec2 velocity = vec2(t + i * 100.0 + n, i + 1.0 + n + cos(t) * 0.5);
    float scale = mix(30.0, 1.0, i);
    float alpha = (1.0 - i) * 0.85;
    vec4 l = landscape((uv * scale) + velocity - mouse);   
    color = mix(color, l * alpha, l.a);
  }

  return color;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec4 color = vec4(0.0);
  float t = u_time * 0.4;

  color = landscapeLayers(uv, t);
  color += rainSystem(uv, t);
  color = vignette(uv, color);
  color += filmGrain(uv);

  gl_FragColor = color;
}