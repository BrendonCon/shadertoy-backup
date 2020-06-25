precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

#define PARTICLE_COUNT 100.0

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 col = vec3(0.0);
  float theta = atan(uv.y, uv.x);
  float d = length(uv);
  float speed = 0.5; 
  float t = u_time * speed;

  for (float i = 0.0; i < PARTICLE_COUNT; i++) {
    float turb = fract(sin(i * 32342.25) * 765892.13);
    t = fract(t) + turb;

    float n = ((i + 1.0) / PARTICLE_COUNT);
    float theta = n * 6.28;
    float x = cos(theta) * turb;
    float y = sin(theta) * turb;
    vec2 pos = vec2(x, y);
    float amplitudeX = t * t + turb;
    float amplitudeY = t * t + turb;
    float vx = cos(theta + t) * amplitudeX;
    float vy = sin(theta + t) * amplitudeY;
    vec2 vel = vec2(vx, vy);

    pos = vel * t;

    float alpha = (sin(t * 6.28) + 1.0) / 2.0;
    float r = fract(sin(i * 3342.1) * 723192.13);
    float g = fract(sin(i * 1567.782) * 56892.13);
    float b = fract(sin(i * 98454.25) * 2346.13);
    vec3 color = vec3(r, g, b);
    float sizeVariance = alpha * 0.01;
    float radius = 0.01 + sizeVariance;
    float radiusOffset = 0.02 + sizeVariance;
    float dist = length((uv - pos) * cos(y * 10.0));
    float particle = 1.0 - smoothstep(radius, radius + radiusOffset, dist);

    col += vec3(particle * alpha * color);
  }
    
  gl_FragColor = vec4(col, 1.0);
}
