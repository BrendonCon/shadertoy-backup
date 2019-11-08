#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

float rand(in vec2 co)
{
  return fract(sin(dot(co.xy ,vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
}

const float layers = 7.0;

void main()
{
  vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
  float t = u_time;
  
  float ar = u_resolution.x / u_resolution.y;
  uv.x *= ar;
  
  float baseScale = 1.0;
  vec3 col = vec3(0.0);
  
  for (float i = 0.0; i < layers; i++) 
  {
    float n = i + 1.0;
    vec2 uv = uv * (n * baseScale + 1.0 / 4.0);
    float z = i / layers;
    
    float vy = t * n * 1.0 / z * 0.035;
    vec2 velocity = vec2(0.0, vy);
    uv += velocity;        
    
    vec2 id = floor(uv);
    vec2 f = fract(uv) - 0.5;
    f.x += rand(id - i) * 0.9;
    f.y += rand(id + i) * 0.9;
    
    float size = 0.025;
    float alpha = min(max(1.0 - z, 0.2), 0.95);
    float d = length(f);
    float c = 1.0 - smoothstep(0.0, size, d);
    float haloSize = size * 2.5;
    float halo = (1.0 - smoothstep(0.0, haloSize, d)) * 0.1;
    
    col += vec3((c + halo) * alpha); 
  }

  gl_FragColor = vec4(col, 1.0);
}