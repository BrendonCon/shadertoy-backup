precision mediump float;

#define PI 3.14
#define TAU 6.28
#define NUM_OCTAVES 8

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
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c, -s, s, c);    
}

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

float circle(in vec2 uv, float radius, float blur) {
	return smoothstep(radius, radius - blur, length(uv));    
}

float rect(in vec2 uv, vec2 size, float blur) {
  vec2 halfSize = size * 0.5;
  float h = smoothstep(halfSize.x, halfSize.x - blur, abs(uv.x));
  float v = smoothstep(halfSize.y, halfSize.y - blur, abs(uv.y));
  return h * v;
}

float particles(in vec2 uv) {
  float particles;
  float t = u_time * 0.75 + 32.4;
  
  for (float i = 0.0; i <= 1.0; i += 1.0 / 30.0) {
    float n = i + 1.0;
    
    uv.x += i + t * 0.02 * n;
    uv.y += i + t * 0.05 * n;
    uv *= rotate(n * TAU);
    uv.x += fract(sin(i) * 345.62);
    uv.y += fract(sin(i) * 35.62);

    vec2 id = floor(uv);
    vec2 guv = fract(uv) - 0.5;
    float seed = hash(id);
    float alpha = mix(0.05, 0.2, i);
    float scale = seed * 0.09 * i;
    float alive = float(seed < 0.6);
    float blur = mix(0.025, 0.075, i);
    vec2 position = vec2(seed) * 0.5;
    float particle = circle(guv - position, scale, blur) * alpha * alive;
    
    particles += particle;
  }
  
  return particles;
}

// TODO: Clean this up
void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;
  uv.x -= 0.15;
  
  // LIGHTS
  vec3 lightColor = vec3(0.74, 0.76, 0.68);
  float lightIntensity = 0.125;
  vec2 lightPosition = vec2(-0.15, 0.65);
  float l = 1.0 / length(uv - lightPosition) * lightIntensity;
  vec3 light = l * lightColor;

  // BACKGROUND
  vec3 bgColor1 = vec3(0.02);
  vec3 bgColor2 = vec3(0.15, 0.14, 0.125);
  vec3 bgColor = mix(bgColor1, bgColor2, uv.y);
  vec3 color = vec3(bgColor);

  // RAYS
  float rayMask = rect(uv * rotate(0.25) + vec2(0.3, 0.0), vec2(0.6, 1.75), 0.2) * 0.9;
  rayMask += rect(uv * rotate(-0.02) + vec2(0.05, 0.0), vec2(0.5, 1.75), 0.2) * 0.75;
  color += rayMask * light; 

  // PARTICLES
  float particleMask = rect(uv * rotate(0.25) + vec2(0.3, 0.0), vec2(0.9, 1.75), 0.2) * 0.9;
  particleMask += rect(uv * rotate(-0.02) + vec2(0.05, 0.0), vec2(0.8, 1.75), 0.2) * 0.75;
  float p = particles(uv * 10.0);
  color += p * particleMask;

  // NOISE
  float n = fract(sin(uv.x * 345.12 + uv.y * 5679.13) * 3986.36);
  color += (vec3(n) * particleMask) * 0.02;

  // ADDITIONAL COLOR GRADIENTS
  float c1 = circle(uv * vec2(0.5, 0.5) + vec2(0.15, 0.5), 0.5, 0.45);
  color += c1 * vec3(0.3, 0.1, 0.75) * 0.065;

  // CLOUDS
  float f = fbm(uv * rotate(u_time * 0.15) * 10.0 + u_time * 0.15);
  f *= fbm(uv * 15.0 + u_time * 0.55);
  color += (f * 0.06) * particleMask;

  // VIG
  float vig = 1.0 - length(uv);
  color *= vec3(vig * 1.5);

  gl_FragColor = vec4(color, 1.0);
}
