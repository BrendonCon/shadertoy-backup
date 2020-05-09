precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  
  vec2 st = gl_FragCoord.xy / u_resolution.y - 0.5;
  st.x *= u_resolution.x / u_resolution.y;
  
  float t = u_time;
  vec3 color = vec3(0.0);

  gl_FragColor = vec4(color, 1.0);
}