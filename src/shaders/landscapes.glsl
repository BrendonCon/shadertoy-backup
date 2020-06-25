precision highp float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;

vec2 mouse = u_mouse.xy / u_resolution - 0.5;

float circle(in vec2 uv, float radius) {
  return smoothstep(radius, radius * 0.99, length(uv));
}

vec4 moon(in vec2 uv, float size) {
  vec2 offset = vec2(0.0, 0.025);
  float circle = circle(uv + offset, size);
  return vec4(circle); 
}

vec4 wave(in vec2 uv) {
  vec4 color = vec4(0.0);
  float y = 0.0;
  int t = int(mod(u_time * 0.25, 5.0));

  if (t == 0) y = uv.y + sin(uv.x * 1.0 + u_time) * 0.125 + sin(uv.x * 2.0 - u_time * 0.2) * 0.13;
  if (t == 1) y = uv.y + abs(cos(uv.x) / sin(uv.x) * 2.0); // spikes
  if (t == 2) y = uv.y + step(abs(sin(uv.x)), 0.75); // step func
  if (t == 3) y = uv.y + step(sin(uv.x), 0.5) + step(sin(uv.x * 0.5), 0.5) + step(sin(uv.x * 0.35), 0.7) + step(sin(uv.x * 0.835), 0.5); // city
  if (t == 4) y = uv.y + sin(uv.x + sin(uv.x * 6.0) * 0.7); // teeth canyon

  float layer = step(y, 0.5);
  return vec4(layer);
}

vec4 waves(in vec2 uv) {
  vec4 color = vec4(0.0);
  float t = u_time * 0.5;

  for (float i = 0.0; i < 1.0; i += 1.0 / 40.0) {
    float scale = mix(30.0, 1.0, i);
    vec2 velocity = vec2(t * (i + 0.25), -mouse.y * 2.0) * 0.5;
    vec2 offset = vec2((i + 1.0) * 4512.6 + (i + 1.0) * i * 10567.4, 0.5 + i * 2.0);
    vec4 wave = wave(uv * scale + offset + velocity);
    float alpha = 1.0 - i;
    color = mix(color, wave * vec4(vec3(alpha), 1.0), wave.a);
  }

  return color;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 bg = vec3(smoothstep(0.6, -0.1, uv.y) * 1.05);
  vec4 color = vec4(bg, 1.0);

  vec4 moon = moon(uv, 0.18);
  color += moon;

  vec4 waves = waves(uv * 6.0);
  color = mix(color, waves * 1.1, waves.a);
  
  gl_FragColor = color;
}
