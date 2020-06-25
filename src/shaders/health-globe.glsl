precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

float circle(in vec2 uv, float radius, float blur) {
    return smoothstep(radius, radius - blur, length(uv));
}

float hash(vec2 p) { 
  return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
}

float noise(in vec2 uv) {
  vec2 guv = floor(uv);
  vec2 id = fract(uv);
  float a = hash(guv);
  float b = hash(guv + vec2(1.0, 0.0));
  float c = hash(guv + vec2(0.0, 1.0));
  float d = hash(guv + vec2(1.0, 1.0));
  vec2 u = id * id * (3.0 - 2.0 * id);

  return mix(a, b, u.x) +
            (c - a) * u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

mat2 rotate(float theta) {
  float s = sin(theta);
  float c = cos(theta);
  return mat2(c, -s, s, c);    
}

#define NUM_OCTAVES 10
float fbm(in vec2 uv) {
  float v = 0.0;
  float a = 0.5;
  vec2 shift = vec2(100.0);
  mat2 rot = rotate(0.5);

  for (int i = 0; i < NUM_OCTAVES; ++i) {
    v += a * noise(uv);
    uv = rot * uv * 2.0 + shift;
    a *= 0.5;
  }

  return v;
}

vec4 healthGlobe(in vec2 uv, float scale, float speed) {
  float dist = length(uv) * 1.51;
  float sphere = (1.0 - sqrt(1.0 - dist)) / dist;

  vec2 pos = uv;
  pos *= sphere;
  pos *= scale;
  
  float t = u_time * speed;
  vec4 color = vec4(0.0);
  vec4 baseColor = vec4(0.517, 0.129, 0.03, 1.0);
  vec4 highlightColor = vec4(0.611, 0.1, 0.007, 1.0) * 1.5;

  vec4 noise = vec4(fbm(pos * vec2(1.0, 3.0) - 0.1 + t * 0.5));
  noise *= vec4(fbm(pos * vec2(1.0, 1.5) - t * 0.2));
  noise *= vec4(fbm(pos * rotate(t * 0.1) * vec2(0.25) - t * 0.5)) * 2.0;
  noise *= vec4(fbm(pos * rotate(t * -0.2) * vec2(0.3) + t * 0.25)) * 2.0;
  noise = mix(baseColor, highlightColor, noise.r);
  color = noise;
  
  vec2 mouse = u_mouse.xy / u_resolution.xy * 2.0 - 1.0;
  vec2 maskPos = uv - vec2(mouse.y);
  float maskWave = fbm(maskPos * 2.0 - t * 0.35) * 0.05;
  vec4 mask = vec4(smoothstep(0.2, 0.175, maskPos.y - maskWave));
  color *= mask;  

  float cloudSpeed = t * 0.3;
  float cloudAlpha = 0.1;
  vec4 clouds = vec4(fbm(pos * 0.3 + cloudSpeed));
  clouds *= vec4(fbm(pos * rotate(t * 0.025) * 0.5 + cloudSpeed));
  color = mix(color, clouds * cloudAlpha, clouds.a); 
  
  vec2 shinePos = uv * rotate(0.5);
  float shine = smoothstep(0.2, 0.5, shinePos.y);
  color += vec4(shine * 0.045);
  
  vec2 innerShadowPos = uv * rotate(-2.2);
  float innerShadow = smoothstep(0.8, 0.0, innerShadowPos.y);
  color *= vec4(innerShadow);
  
  float spec1 = 1.0 / length(uv - vec2(0.325)) * 0.03;
  color += vec4(spec1) * smoothstep(0.75, 0.0, length(uv));
  
  vec2 spec2Pos = uv * rotate(0.6) + vec2(0.2, 0.15);
  vec4 spec2 = vec4(circle(spec2Pos, 0.5, 0.1) - circle(spec2Pos - 0.1, 0.5, 0.2));
  spec2 *= circle(spec2Pos, 0.4, 0.1);
  color += spec2 * 0.02;
  
  float fresnel = smoothstep(1.075, 0.75, dist);
  color *= vec4(fresnel); 
  
  vec4 ao = vec4(circle(uv, 0.95, 0.075) - circle(uv, 0.68, 0.04));
  color = mix(color, ao * 0.075, ao.a);
  
  return color;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;
  uv *= 2.5;

  vec4 color = healthGlobe(uv, 20.0, 0.75);
  color.a = 1.0;

  gl_FragColor = color;
}
