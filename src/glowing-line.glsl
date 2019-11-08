#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

#define white vec3(1.0)
#define red vec3(1.0, 0.0, 0.0)
#define yellow vec3(1.0, 1.0, 0.0)
#define blue vec3(0.0, 0.0, 1.0)
#define green vec3(0.0, 1.0, 0.0)

vec3 glowingLine(in vec2 uv, float thickness, vec3 color1, vec3 color2)
{
  float line = abs(uv.y);  
  
  line = 1.0 / line * thickness;
  
  vec3 color = mix(color2, color1, line);
  float intensity = 50.0;
  
  color += mix(white, color2, abs(uv.y * intensity));
  
  return vec3(line) * color;  
}

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

#define USE_FBM false
#define OPTION_A false
void main()
{
  vec2 uv = gl_FragCoord.xy / u_resolution - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;
  
  if (USE_FBM)
  {
    float t = u_time * 0.1;
    float f = fbm(uv * 2.0 - t) * 0.1;

    mat2 A = rotate(u_time * 0.025);
    f += fbm(uv * A * 5.5 - t) * 0.1;

    mat2 B = rotate(u_time * 0.01);
    f += fbm(uv * B * 1.5 - t) * 0.015;

    uv *= length(vec2(uv.x, uv.y));
    uv.y += sin(f); 
  } 
  else
  {
    uv.y += sin(uv.x * 0.1) * sin(uv.y * 10.0 + u_time);   
  }
  
  vec3 line;

  if (OPTION_A)
  {
    line = glowingLine(uv, 0.0025, yellow, red) * 1.5;    
  }
  else
  {
    float t = u_time * 0.5;
    float amplitude = 1.25;

    vec3 glowColor = vec3(
      abs(sin(t) * amplitude),
      abs(cos(t) * amplitude),
      abs(sin(t * 0.5) * amplitude)
    );
    
    line = glowingLine(uv, 0.003, glowColor, glowColor) * 1.15;
  }
  
  gl_FragColor = vec4(line, 1.0);
}