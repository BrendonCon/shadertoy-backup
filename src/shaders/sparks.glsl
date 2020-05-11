precision mediump float;

#define TAU 6.283185
#define PI 3.141592
#define ORANGE vec4(1.0, 0.65, 0.0, 1.0)
#define BLUE vec4(0.0, 0.2, 0.8, 1.0)
#define PARTICLE_COUNT 100.0

uniform float u_time;
uniform vec2 u_resolution;

vec4 light(in vec2 uv, float intensity) {
  return vec4(1.0 / length(uv) * intensity);
}

vec4 particles(in vec2 uv, in float time, vec2 origin, float speed) {
  vec4 particles;

  time *= speed;

  for (float i = PARTICLE_COUNT; i >= 0.0; i--) {
    float n = (i + 1.0) / PARTICLE_COUNT;
    float seed = fract(sin(n * 456.321) * 975.34);
    float theta = mix(-PI, -TAU, n);
    float t = fract(time + seed + n);
    
    float maxX = seed * 1.35;
    float maxY = seed * 3.0 + 1.0;
    vec2 amplitude = vec2(mix(0.0, maxX, t), mix(0.1, maxY, t));
    vec2 acceleration = vec2(0.0, 2.5 * t * t);
    vec2 velocity = vec2(cos(theta), sin(theta)) * amplitude;
    vec2 position = uv - origin - (velocity - acceleration) * 0.325;
    
    float alpha = clamp(1.0 - t, 0.0, 1.0);
    float size = mix(0.015, 0.0, t);
    vec4 color = mix(BLUE, ORANGE, (sin(time) + 1.0) / 2.0);
    vec4 particle = light(position, size) * alpha;
    
    particles = mix(particles, max(particle * color, particles), particle.a);
  }

  return particles;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec4 color = vec4(0.0);
  color += particles(uv, u_time, vec2(0.1, 0.0), 0.5);
  color += particles(uv, u_time + 5.0, vec2(-0.125, 0.0), 0.5);

  vec4 flare = light(uv * vec2(1.0, 75.0), 0.3);
  color *= flare;

  float radialGradient = (1.0 - length(uv)) * 0.03;
  color += radialGradient;
  color.a = 1.0;

  gl_FragColor = color;
}
