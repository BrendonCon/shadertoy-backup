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
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c, -s, s, c);    
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

float rect(in vec2 uv, vec2 size) {
  vec2 halfSize = size * 0.5;
  float w = smoothstep(halfSize.x, halfSize.x - 0.001, abs(uv.x));
  float h = smoothstep(halfSize.y, halfSize.y - 0.001, abs(uv.y));
  return w * h;
}

vec4 rgbNorm(float r, float g, float b) {
	return vec4(r / 255.0, g / 255.0, b / 255.0, 1.0);    
}

vec4 background(in vec2 uv) {
  vec4 color1 = rgbNorm(152.0, 28.0, 149.0);
  vec4 color2 = rgbNorm(23.0, 7.0, 70.0);    
  float g = abs(uv.y * 2.0);
  return mix(color1, color2, g);
}

vec4 buildings(in vec2 uv) {
  vec4 color;
  vec2 p = abs(uv);
  
  vec4 b1 = vec4(rect(p - vec2(0.2, 0.15), vec2(0.1, 0.3)));
  b1 += vec4(rect(p - vec2(0.154, 0.15), vec2(0.01, 0.3))) * 0.75;
  
  vec4 b2 = vec4(rect(p - vec2(0.4, 0.1), vec2(0.1, 0.2)));
  b2 += vec4(rect(p - vec2(0.354, 0.1), vec2(0.01, 0.2))) * 0.75;
  
  vec4 b3 = vec4(rect(p - vec2(0.6, 0.05), vec2(0.1, 0.1)));
  b3 += vec4(rect(p - vec2(0.554, 0.05), vec2(0.01, 0.1))) * 0.75;
  
  vec4 b4 = vec4(rect(p - vec2(0.0, 0.2), vec2(0.1, 0.4)));
  vec4 b = b1 + b2 + b3 + b4;
  
  if (uv.y <= 0.0) {
    color += b * rgbNorm(47.0, 16.0, 84.0);
  } else {
    color += b * rgbNorm(45.0, 28.0, 99.0);    
  }
  
  return color;
}

vec4 fog(in vec2 uv) {
  vec4 fog = vec4(fbm(uv * 5.0 + vec2(u_time * 0.01, 0.0)));
  return fog * 0.5;
}

vec4 smoke(in vec2 uv) {
  vec4 color;
  float t = u_time * 0.25;
  
  float smoke = fbm(uv * 10.0 + t);
  smoke *= fbm(uv * 10.0 - t);
  smoke *= fbm(uv * 6.0 + t);
  smoke *= 1.75;
  color += smoke * rgbNorm(46.0, 174.0, 199.0);
  color *= smoothstep(0.1, 0.0, abs(uv.y));
  
  return color * 1.25;
}

vec4 landscape(in vec2 uv) {
  vec4 color = rgbNorm(45.0, 28.0, 99.0);
  float w = fbm(uv * vec2(10.0, 5.0)) * 0.05;

  vec4 back = vec4(smoothstep(0.05, 0.04, abs(uv.y) - fbm(uv * vec2(10.0, 5.0)) * 0.2));
  back *= 0.15;
  
  vec4 front = vec4(smoothstep(0.016, 0.015, abs(uv.y) - fbm(uv * vec2(10.0, 5.0)) * 0.05)); 
  
  return mix(back, front, front.a) * color;
}

vec4 stars(in vec2 uv) {
  float n = hash(uv * 70.0);
  n *= hash(uv * 10.0);
  n = smoothstep(0.0001, 0.0, n);

  float alpha = fbm(uv * 10.0 + u_time);

  return vec4(n * alpha) * smoothstep(0.0, 0.5, uv.y);  
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  vec4 color;
  
  uv.x *= u_resolution.x / u_resolution.y;
  uv *= 1.25;
  uv.y += 0.1;
  
  float isWater = smoothstep(0.025, -0.125, uv.y);
  uv += fbm(uv * vec2(10.0, 40.0) + vec2(u_time) * 0.8) * 0.04 * isWater;
  
  vec4 background = background(uv);
  color += background;
  
  vec4 stars = stars(uv);
  color += stars;
  
  vec4 landscape = landscape(uv);
  color = mix(color, landscape, landscape.a);

  vec4 buildings = buildings(uv);
  color = mix(color, buildings, buildings.a);
  
  vec4 lightColor = rgbNorm(46.0, 174.0, 199.0);
  float light = 1.0 / length(vec2(0.0, uv.y + 0.005)) * 0.01;
  color += light * lightColor;
  
  vec4 fog = fog(uv);
  color = mix(color, fog * 0.01, fog.a);
  
  vec4 smoke = smoke(uv);
  color += smoke;
      
  float vig = 1.0 - length(gl_FragCoord.xy / u_resolution.xy - 0.5);
  color *= vec4(vig);
  
  vec4 noise = vec4(hash(uv + u_time));
  color += noise * 0.035;

  gl_FragColor = color * 1.1;
}