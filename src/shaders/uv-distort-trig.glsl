precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
  float ar = u_resolution.x / u_resolution.y;

  uv.x *= ar;

  float a = atan(uv.y, uv.x);
  float r = length(uv);
  float n = 10.0;
  vec3 col = vec3(cos(a * n - sin(r * n - u_time) * cos(u_time) * n));

  gl_FragColor = vec4(col, 1.0);
}