precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;
uniform vec2 u_mouse;

struct ray {
  vec3 origin;
  vec3 direction;
};

struct surface {
  vec3 normal;
  int steps;
  float dist;
  vec3 point;
  bool isHit;
  vec3 albedo;
  int id;
};

struct marchConfig {
  float BIAS;
  int MAX_STEPS;
  float FAR;
  float NEAR;
};

mat2 rotate(float theta) {
  float c = cos(theta);
  float s = sin(theta);
  return mat2(c, -s, s, c);    
}

float box2d(vec2 p, vec2 size) {
  p = abs(p) - size;
  return length(max(p, 0.0)) + min(max(p.x, p.y), 0.0);
}

surface scene(vec3 p) {
  float radius1 = 1.7;
  float radius2 = 0.2;

  vec2 t = vec2(length(p.xz) - radius1, p.y);
  float theta = atan(p.x, p.z);
  t *= rotate(theta * 0.5 + u_time);
  t.y = abs(t.y) - 0.5;

  float torii = length(t) - radius2;
  torii = box2d(t, vec2(0.1, 0.2 * (sin(theta) * 0.5 + 0.5))) - 0.05;

  surface surf;
  surf.dist = torii;
  surf.albedo = vec3(0.7);
      
  return surf;
}

vec3 normal(vec3 p) {
  float e = 0.001;
  vec3 n;
  n.x = scene(p + vec3(e, 0, 0)).dist - scene(p - vec3(e, 0, 0)).dist;
  n.y = scene(p + vec3(0, e, 0)).dist - scene(p - vec3(0, e, 0)).dist;
  n.z = scene(p + vec3(0, 0, e)).dist - scene(p - vec3(0, 0, e)).dist;
  return normalize(n);
}

float ao(in vec3 p, in vec3 n) {
  float e = 1.0;
  float res = 0.0;
  float weight = 1.0;

  for (int i = 0; i <= 10; i++) {
    float d = e * float(i);
    res += weight * (1.0 - (d - scene(p + d * n).dist));
    weight *= 0.5;
  }

  return res;
}

float shadow(in vec3 p, in vec3 l) {
  float t = 0.01; 
  float t_max = 10.0;
  float k = 2.0;
  float res = 1.0;

  for (int i = 0; i < 64; i++) {
    if (t > t_max) break;

    float d = scene(p + l * t).dist;

    if (d < 0.001) {
      return 0.0; 
    }

    t += d * 0.5;
    res = min(res, k * d / t); 
  }

  return res;    
}
    
surface march(vec3 ro, vec3 rd, marchConfig config) {
  surface surf;
  float t;

  for (int i = 0; i < 256; i++) {
    if (t > config.FAR) break;

    vec3 p = ro + rd * t;
    surface s = scene(p);        

    t += s.dist * config.BIAS;

    if (abs(s.dist) < config.NEAR) {
      s.isHit = true;
      s.normal = normal(p);
      s.steps = i;
      s.point = p;
      surf = s;
      break;
    }
  }

  return surf;
}

vec3 envMap(vec3 rd) {
  float x = rd.y * 0.5 + 0.5;
  return mix(vec3(0.4, 0.2, 0.1), vec3(0.1, 0.25, 1), x);
}

vec3 computeColor(vec3 ro, vec3 rd, marchConfig config) {
  vec3 color = envMap(rd);
  
  for (float i = 0.0; i < 4.0; i++) {
    surface surf = march(ro, rd, config);

    if (surf.isHit) {
      vec3 p = surf.point;
      vec3 n = surf.normal;
      vec3 r = reflect(rd, n);
      vec3 l = vec3(1, 2, 3);

      // DIFFUSE
      float dif = max(dot(n, normalize(l)), 0.0) * 0.5 + 0.5;    

      // SPEC
      float spec = max(r.y, 0.0);
      spec = pow(spec, 10.0);
      spec *= 0.75;

      // AO
      color *= min(vec3(ao(p, n)), vec3(1));

      // FRESNEL
      float bias = 0.1;
      float scale = 1.0;
      float fresnelStr = 0.01;
      float fresnel = fresnelStr * (bias + scale * pow(1.0 + dot(l, n), 3.0));

      // COMPOSITE
      color += mix(envMap(r), surf.albedo * dif * fresnel, 0.5) * (shadow(p, l) + 0.1);   
      color += spec;

      rd = reflect(normalize(p - ro), n);
      ro = p + rd * 0.5;
    }
  }

  return color;
}

vec3 render(vec2 fragCoord) {
  vec2 uv = fragCoord / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  ray camera;
  camera.origin = vec3(0, 0, 6);
  camera.direction = normalize(vec3(uv, -1));

  marchConfig config;
  config.BIAS = 0.75;
  config.MAX_STEPS = 256;
  config.FAR = 256.0;
  config.NEAR = 0.001;

  return computeColor(camera.origin, camera.direction, config);
}

#define AA

void main() {
  vec3 color;
  
  #ifdef AA
      color += render(gl_FragCoord.xy + vec2(0.2));
      color += render(gl_FragCoord.xy + vec2(-0.2, 0.2));
      color += render(gl_FragCoord.xy + vec2(-0.2));
      color += render(gl_FragCoord.xy + vec2(0.2, -0.2));
      color /= 4.0;
  #else
      color = render(gl_FragCoord.xy);
  #endif 
    
  gl_FragColor = vec4(pow(color, vec3(0.4545)), 1.0);
}