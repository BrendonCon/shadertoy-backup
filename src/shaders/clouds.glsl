precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float random(in vec2 p) {
  return fract(sin(dot(p.xy, vec2(2.34, 0.2))) * 586.273458);   
}

mat2 rotate(float theta) {
  return mat2(cos(theta), -sin(theta),
              sin(theta), cos(theta));
}

float noise(in vec2 st) {
  vec2 i = floor(st);
  vec2 f = fract(st);

  float a = random(i);
  float b = random(i + vec2(1.0, 0.0));
  float c = random(i + vec2(0.0, 1.0));
  float d = random(i + vec2(1.0, 1.0));

  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(a, b, u.x) +
        (c - a) * u.y * (1.0 - u.x) +
        (d - b) * u.x * u.y;
}

float fbm(in vec2 st) {
  const int octaves = 8;
  float value = 0.0;
  float amplitude = 0.5;
  float frequency = 0.0;
  
  mat2 rot = rotate(0.5);
  
  for (int i = 0; i < octaves; i++) {
    value += amplitude * noise(st);
    st *= 2.0;
    st *= rot;
    amplitude *= 0.5;
  }
  
  return value;
}

#define black vec3(0.0)
#define white vec3(1.0)

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float t = u_time * 0.5;
  
  uv.x *= u_resolution.x / u_resolution.y;
  
  float clouds1 = fbm(uv * vec2(5.0) + vec2(t * 0.15, -t * 0.1));
  clouds1 = smoothstep(0.5, 0.0, clouds1) * 1.5;
  
  float clouds2 = fbm(uv * vec2(2.0) + vec2(t * 0.2, -t * 0.05));
  clouds2 = smoothstep(0.7, 0.1, clouds2);

  float clouds3 = fbm(uv * vec2(4.0) + vec2(t * 0.1,  -t * 0.1));
  clouds3 = smoothstep(0.5, 0.0, clouds3);
  
  vec3 composite = vec3(mix(mix(clouds1, clouds3, 0.5), clouds2, 0.5));
  vec3 bgColor = vec3(0.15, 0.35, 0.75);
  
  composite += bgColor * (1.0 - composite);
  composite = clamp(composite, black, white);
  
  gl_FragColor = vec4(composite, 1.0);
}
