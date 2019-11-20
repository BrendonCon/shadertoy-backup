precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

const int AMOUNT = 10;
const float SCALE = 10.0;

void main() 
{
  vec2 uv = gl_FragCoord.xy / u_resolution - 0.5;
	float ar = u_resolution.x / u_resolution.y;

  uv.x *= ar;
  uv *= SCALE;
  
  float dist = length(uv);
  float radius = dist * 0.25;
  float sphere = (1.0 - sqrt(1.0 - radius)) / radius;
  uv *= sphere * 2.0; 

  float len;
  
  for (int i = 0; i < AMOUNT; i++) 
  {
      len = length(uv);
      uv.x -= cos(uv.y + sin(len) + u_time * 0.5) + cos(u_time / 9.0);
      uv.y += sin(uv.x + cos(len)) + sin(u_time / 10.0);
  }
      
  vec3 color = vec3(
    cos(len * 2.0), 
    cos(len), 
    cos(len)
  );
  
  gl_FragColor = vec4(color, 1.0);
}