precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;
  
  float t = u_time;
  vec4 color = vec4(0.0);

  gl_FragColor = color;
}
