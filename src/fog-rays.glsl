#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

float hash(vec2 p) 
{ 
  return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
}

float noise(in vec2 uv) 
{
  vec2 i = floor(uv);
  vec2 f = fract(uv);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(a, b, u.x) +
            (c - a) * u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

mat2 rotate(float theta)
{
  return mat2(cos(theta), -sin(theta),
              sin(theta), cos(theta));    
}

#define NUM_OCTAVES 10
float fbm(in vec2 uv) 
{
  float v = 0.0;
  float a = 0.5;
  vec2 shift = vec2(100.0);
  mat2 rot = rotate(0.5);

  for (int i = 0; i < NUM_OCTAVES; ++i) 
  {
      v += a * noise(uv);
      uv = rot * uv * 2.0 + shift;
      a *= 0.5;
  }

  return v;
}

void main()
{
  vec2 coords = gl_FragCoord.xy / u_resolution;
  vec2 uv = gl_FragCoord.xy / u_resolution * 2.0 - 1.0;
  float ar = u_resolution.x / u_resolution.y;
  float t = u_time * 0.5;
  vec3 col = vec3(0.0);

  // background color
  vec3 b1 = vec3(.0 / 255.0, 10.0 / 255.0, 20.0 / 255.0);
  vec3 b2 = vec3(35.0 / 255.0, 77.0 / 255.0, 115.0 / 255.0);
  float b = smoothstep(0.0, 1.25, coords.y);
  vec3 bg = mix(b1, b2, 0.5) - 0.2;
  col = vec3(bg);

  // rays
  vec2 offset = vec2(0.0, -1.2);
  uv += offset;
  float a = atan(uv.y, uv.x);
  vec3 rays1 = vec3(sin(a * 20.0 + t));
  vec3 rays2 = vec3(sin(a * 90.0 - t));
  col = mix(rays1, col, 0.98);
  col = mix(rays2, col, 0.995);

  // main light
  float d = length(uv);
  d = length(d * vec2(10.0, 5.0));
  float intensity = 2.0;
  vec3 light = vec3(1.0 / d);
  col += light * intensity + cos(t * 5.0) * 0.005;

  // additional lighting
  float al = noise(uv * 0.5 + t);
  float addLightIntensity = 0.05;
  vec3 addLight = vec3(al) * addLightIntensity;
  col += addLight;

  // vignette
  float v = smoothstep(0.0, 2.75, length(uv));
  vec3 vignette = vec3(1.0 - v);
  col += vignette * 0.125;

  // fog
  vec3 fbm1 = vec3(fbm(uv * rotate(t * 0.1) * 10.5 + vec2(t * 0.2, t * 0.1)));
  vec3 fbm2 = vec3(fbm(uv * rotate(t * -0.15) * 5.0 + vec2(t * 0.5, 0.0)));
  vec3 fbm3 = vec3(fbm(uv * 5.0 * rotate(t * 0.05) + vec2(t * 0.25, -t * 0.25)));
  vec3 fog = mix(fbm1, fbm2, 0.5);
  fog = mix(fog, fbm3, 0.5);
  col = mix(col, fog, 0.1);

  // noise
  vec3 n1 = vec3(noise(uv * 50.1));
  vec3 n2 = vec3(noise(uv * 100.1));
  float noiseIntensity = 0.01;
  vec3 n = (n1 * n2) * noiseIntensity;
  col += n;

  // frame
  float f = smoothstep(1.0, 0.4, length(coords - 0.5));
  vec3 frame = vec3(1.0 - f);   
  col -= frame * 0.1; 

  gl_FragColor = vec4(col, 1.0);
}