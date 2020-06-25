precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

float hash(vec2 p) { 
  return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
}

float noise(in vec2 uv) {
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

mat2 rotate(float theta) {
  return mat2(cos(theta), -sin(theta),
              sin(theta), cos(theta));    
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

vec3 rgb(float r, float g, float b) {
  return vec3(r / 255.0, g / 255.0, b / 255.0);
}

vec3 rgb(float x) {
  return vec3(x / 255.0);
}

float circle(in vec2 uv, float radius, float blur) {
	return smoothstep(radius, radius - blur, length(uv));    
}

float rect(in vec2 uv, vec2 size, vec2 blur) {
  float w = smoothstep(size.x, size.x - blur.x, abs(uv.x));
  float h = smoothstep(size.y, size.y - blur.y, abs(uv.y));
  return w * h;
}

vec4 background(in vec2 uv) {
  vec4 g1 = vec4(rgb(2.0, 2.0, 2.0), 1.0) * 1.5;
  vec4 g2 = vec4(rgb(2.0, 2.0, 2.0), 1.0) * 0.05;
  vec4 background = mix(g1, g2, uv.y);
  vec4 blueHighlight = vec4(circle(uv, 0.5, 0.3));
  return background;
}

vec4 clouds(in vec2 uv) {
  vec4 clouds = vec4(fbm(uv * 10.0) * 0.6) * 1.1;

  float x1 = fbm(uv * 10.0) * 1.5;
  float x2 = fbm(uv * 20.0);
  uv *= rotate(0.5);
  float mask = smoothstep(x1, x2 * 0.6, abs(uv.x));
  clouds *= mask;

  vec4 color = vec4(rgb(25.0, 24.0, 29.0), 1.0) * 5.0;

  return clouds * color;
}

vec4 stars(in vec2 uv) {
  vec4 stars;
  float scale = 20.0;

  uv *= scale;

  vec2 id = floor(uv);
  vec2 guv = fract(uv);

  float x = noise(id);
  float y = noise(id * 10.0);
  float alpha = noise(id * 10.0) * 0.4;
  float size = noise(id) * 0.07;
  vec2 position = vec2(x, y) * 0.5;
  float star = 1.0 / (length(guv - position)) * size * 0.2;

  stars += smoothstep(0.03, 0.0, noise(uv * 30.0));
  stars *= fbm(uv * 10.0);
  stars += star * alpha;

  return stars;
}

vec4 planet(in vec2 uv, vec2 position, float radius, float blur) {
  uv -= position;

  vec4 planet;
  vec4 planetBase = vec4(circle(uv, radius, blur));
  vec4 innerGlow = planetBase - vec4(circle(uv, radius * .99, 0.05));
  
  vec4 shadow = vec4(circle(uv * vec2(0.65, 1.0) + vec2(0.0, 0.1), radius, 0.13));
  shadow.rgb = vec3(0.01 * uv.y * 3.0);
  
  vec4 tex;
  vec4 color = vec4(rgb(107.0, 82.0, 42.0) * 2.0, 1.0);

  float r = sqrt(dot(uv, uv));
  float maxR = 1.0;
  float speed = 0.0;
  
  if (r < maxR) {
    vec2 coords;
    float f = ((1.0 - sqrt(1.0 -r)) / (r)) * 1.5;
    coords.x = uv.x * f + u_time * speed;
    coords.y = uv.y * f + u_time * speed;
    tex = vec4(vec3(fbm(coords * vec2(10.0, 20.0))), 1.0) * 1.1;
  }
  
  planetBase += vec4(vec3(tex * tex), 0.0) * planetBase;
  planetBase *= vec4(0.5, 0.5, 0.5, 1.0) * color;
  planetBase += innerGlow * 0.15;
  planet = mix(planetBase, planetBase * shadow, shadow.a);
  
  return planet;
}

float frame(in vec2 uv, vec2 size) {
  float r = rect(uv, size, vec2(0.001));
  float mask = smoothstep(1.2, 0.2, uv.x);
  return r * mask;
}

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;
  
  vec4 background = background(uv);
  vec4 clouds = clouds(uv);
  vec4 stars = stars(uv);
  vec4 bigPlanet = planet(uv, vec2(0.0, -0.6), 0.8, 0.006);
  vec4 smallPlanet = planet(uv * 7.0, vec2(0.2, -1.25), 0.6, 0.03);
  float frame = frame(uv, vec2(1.0, 0.375));
  
  vec4 color;
  color = background;
  color = mix(color, clouds * 0.15, clouds.a);
  color += circle(uv - 0.5, 0.3, 0.2) * vec4(rgb(12.0, 20.0, 32.0), 1.0) * 0.5;
  color += circle(uv - vec2(-0.3, 0.1), 0.3, 0.2) * vec4(rgb(12.0, 20.0, 32.0), 1.0) * 0.5;
  color = mix(color, stars, stars.a) * (1.0 - bigPlanet.a);
  color = mix(color, bigPlanet, bigPlanet.a);
  color = mix(color, smallPlanet, smallPlanet.a);
  color += noise(uv * 1000.0) * 0.01;
  color *= vec4(frame);
  color.a = 1.0;

  gl_FragColor = color;
}
