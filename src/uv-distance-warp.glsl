precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

void main()
{
  vec2 uv = gl_FragCoord.xy / u_resolution - 0.5;
  float ar = u_resolution.x / u_resolution.y;
	float t = u_time * 0.5;
    
  uv.x *= ar;
  uv.x += 0.1 * cos(10.0 * uv.y + t);
  uv.y += 0.1 * sin(10.0 * uv.x + t);
    
  float d = length(uv);
  float r = 5.0 * sin(d * 100.0);
  vec3 color = vec3(r);
  
  color = smoothstep(0.001, 0.785, color);

  gl_FragColor = vec4(color, 1.0);
}