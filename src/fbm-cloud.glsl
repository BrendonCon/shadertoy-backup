#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

float hash(vec2 p) 
{ 
  return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
}

float noise(in vec2 uv) 
{
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

mat2 rotate(float theta)
{
  return mat2(cos(theta), -sin(theta),
              sin(theta), cos(theta));    
}

#define NUM_OCTAVES 10
float fbm(in vec2 uv) 
{
  float v = 0.0;
  float a = 0.5;
  vec2 shift = vec2(100.0);

  mat2 rot = rotate(0.5);
  
  for (int i = 0; i < NUM_OCTAVES; ++i) 
  {
      v += a * noise(uv);
      uv = rot * uv * 2.0 + shift;
      a *= 0.5;
  }
  
  return v;
}

void main()
{
  vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
  float t = u_time * 0.2;
  float dist = length(uv) * 0.9;
    
  float ar = u_resolution.x / u_resolution.y;
  uv.x *= ar;

  float f1 = fbm(uv * 8.1 + vec2(t));
  float f2 = fbm(uv * 5.1 + vec2(t));
  float f3 = fbm(uv * 2.5 + vec2(t * 0.5));
  float f4 = fbm(uv * 2.0);
  
  float f = mix(f1, f2, 0.5);
  f = mix(f, f3, 0.5);
  f = mix(f, f4, 0.5);
    
  float circle = smoothstep(f, f * 0.5, dist);
  vec3 cloud = vec3(circle * f);
  vec3 blue = vec3(0.15, 0.35, 0.75);
  vec4 composite = vec4(blue + cloud, 1.0);
    
  gl_FragColor = composite;
}