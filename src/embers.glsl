precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float circle(vec2 uv, float radius, float blur) {
  return smoothstep(radius, radius - blur, length(uv));
}

mat2 rotate(float theta) {
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c, -s, s, c);    
}

vec4 ember(in vec2 uv, float radius, float seed) {    
  float n = fract(sin(seed * 456.2314) * 9736.123);
  float globalSpeed = 0.5;
  float speed = mix(0.55, 0.7, n) * globalSpeed;
  float exponent = mix(3.0, 5.0, n);
  float t = pow(fract(u_time * speed + n * 12343.5), exponent);
  
  vec2 position;
  position.x = mix(-0.25, 0.5, n) + sin(seed + t) + t;
  position.y += -0.25 + t * 1.5;
  uv -= position - 0.5;
  
  float theta = atan(uv.x, uv.y);
  uv *= rotate(theta);
  
  float alpha = 1.0 - t;
  float mask = circle(uv, radius, alpha);
  vec4 orange = vec4(246.0 / 255.0, 96.0 / 255.0, 0.0, 1.0);
  float glow = mix(0.125, 0.01, n);
  vec4 ember = vec4(1.0 / length(uv) * glow);
  ember *= orange * 2.0;
    
  return ember * alpha * mask;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  float dist = length(uv);
  vec4 bg = vec4(0.47, 0.17, 0.0, 1.0);    
  vec4 color = vec4(vec3(1.0 - dist), 1.0) * bg * 1.25;
  color += smoothstep(0.5, 0., dist) * 0.1;
  color.rgb *= 1.0 - dist;
  
  const float particleCount = 350.0;
  
  for (float i = 0.0; i <= 1.0; i += 1.0 / particleCount) {
    color += ember(uv, 0.075, (i + 1.0) * 10.0);    
  }

  gl_FragColor = color;
}