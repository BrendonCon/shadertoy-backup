precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

#define rainDebug false
#define rainSpeed 40.0
#define rainDisplacement true
#define mainDropStrength 30.0
#define trailDropStrength 15.0
#define S(a, b, t) smoothstep(a, b, t)

vec2 rain(in vec2 uv, float t)
{
  t *= rainSpeed;
  
  if (rainDisplacement)
  {
    uv.x += sin(uv.y * 70.0) * 0.005;
    uv.y += sin(uv.x * 80.0) * 0.003; 
  }
  
  vec2 ar = vec2(3.0, 1.0);
  vec2 st = uv * ar;
  
  vec2 id = floor(st);

  st.y += t * 0.23;
  
  float n = fract(sin(id.x * 76.34) * 768.34);

  st.y += n;
  uv.y += n;
  id = floor(st); // get new correct ids
  st = fract(st) - 0.5; // center fract uv space
  t += fract(sin(id.x * 76.34 + id.y * 1453.7) * 768.34) * 6.28;

  float y = -sin(t + sin(t + sin(t) * 0.5)) * 0.43;
  vec2 p1 = vec2(0.0, y);
  vec2 o1 = (st - p1) / ar;
  float d = length(o1);
  float m1 = S(0.07, 0.06, d); // main drop
  
  // get normals
  vec2 o2 = (fract(uv * ar.x * vec2(1.0, 2.0)) - 0.5) / vec2(1.0, 2.0);
  d = length(o2);

  // trail drops
  float m2 = S(0.3 * (0.5 - st.y), 0.0, d) * S(-0.1, 0.1, st.y - p1.y);

  // borders debug
  if (rainDebug)
  {
    if (st.x > 0.46 || st.y > 0.49)
    {
      m1 = 1.0;
    }  
  }
  
  return vec2(m1 * o1 * mainDropStrength + m2 * o2 * trailDropStrength);
}

void main()
{
  vec2 uv = gl_FragCoord.xy / u_resolution;
  uv *= u_resolution.x / u_resolution.y;

  vec2 rainDrops = rain(uv * 6.0, u_time * 0.01);
  uv -= rainDrops;
  vec3 color = vec3(uv.y);

  gl_FragColor = vec4(color, 1.0);
}