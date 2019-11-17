#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

void main()
{
  vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
  uv.x *= u_resolution.x / u_resolution.y;
  
  vec2 st = uv;
  float t = u_time * 0.5;
  float t2 = t * 0.1;
  float scale = mix(0.001, 1.0, fract(t * 0.002));
  float n1 = fract(sin(uv.x * 0.1) * 1293.23);
  float n2 = fract(sin(uv.y * 3345.64) * 123.23);

  uv.y *= n1;
  uv.y += n1;
  uv.y += t * 0.1;
  
  uv *= mat2(cos(t * uv.x * scale), -sin(t),
             sin(t), cos(t));
  
  st *= mat2(cos(t2), -sin(t2),
             sin(t2), cos(t2));

  float a = sin(uv.y + t);
  float b = cos(uv.x - t);
  float c = sin(st.y) * 0.25;
  float d = sin(st.y - t) * 0.25;

  vec3 baseColor = 0.5 + 0.5 * cos(u_time + uv.xyx + vec3(0.0, 2.0, 4.0));
  vec3 color = vec3(1.0 / abs(a + b + d + c * 15.0) * 0.2);
  color *= baseColor;
  color *= 0.4;
  
  gl_FragColor = vec4(color, 1.0);
}