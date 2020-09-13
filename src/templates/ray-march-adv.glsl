/*
  @desc: More advanced ray marching starting template
  - We make use of structs for sceneObjects, intersection data, camera etc
  - Control the specifics of the object via its id
  - Control material specifics using matId
  - Intersection object from trace routine gives us all data
*/

precision mediump float;

uniform vec2 u_resolution;
uniform float u_time;

// =========== Structs/types ===========

/*
  @name: sceneObj 
  @desc: struct used to represent scene geometries
      can use id for specific object
      can use matId for materials specifics
*/

struct sceneObj 
{
  int id;
  int matId;
  float sdf;
  vec3 position;
  vec3 color;
};

/*
  @name: intersection
  @desc: intersection point data
    provides distance(dist), 
    steps taken (steps),
    intersection point (p)
    normal vector (n)
    scene object we intersect with (obj)
*/

struct intersection 
{
  bool isHit;
  float dist;
  int steps;
  vec3 p;
  vec3 n;
  sceneObj obj;
};
    
/*
  @name: camera
  @desc: structure to house camera data
*/
  
struct camera 
{
  vec3 origin;
  vec3 direction;
};

// =========== Prototype declarations ===========
    
sceneObj scene(vec3);
vec3 normal(vec3);
intersection trace(vec3, vec3);

// =========== Geometries =========== 

float sphere(vec3 p, float radius)
{
  return length(p) - radius;
}

float plane(vec3 p)
{
  return p.y;
}

float box(vec3 p, vec3 size) 
{
  vec3 q = abs(p) - size;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// =========== Rotations ===========

mat3 rotateX(float theta) 
{
  float s = sin(theta);
  float c = cos(theta);

  return mat3(1, 0, 0,
              0, c, -s,
              0, s, c);
}

mat3 rotateY(float theta) 
{
  float s = sin(theta);
  float c = cos(theta);

  return mat3(c, 0, s,
              0, 1, 0,
              -s, 0, c);
}

mat3 rotateZ(float theta) 
{
  float s = sin(theta);
  float c = cos(theta);

  return mat3(c, -s, 0,
              s, c, 0,
              0, 0, 1);	    
}

// =========== Utilities =========== 

/*
  @name: minObj
  @desc: compares to objects and returns the one closer
*/

sceneObj minObj(sceneObj a, sceneObj b)
{
  if (a.sdf < b.sdf) return a;
  return b;    
}

// =========== Scene =========== 

/*
  @name: scene
  @desc: essentially our scene graph
      used to check distances against all objects in scene
*/

sceneObj scene(vec3 p)
{
  sceneObj s1;
  s1.sdf = sphere(p, 0.5);
  s1.color = vec3(1, 0, 0);

  sceneObj p1;
  p1.sdf = plane(p + vec3(0, 1, 0));
  p1.color = vec3(0, 0, 1);

  sceneObj obj;
  obj = s1;
  obj = minObj(p1, obj);

  return obj;
}

/*
  @name: normal
  @desc: compute the normal to a vector using derivatives
    returns orthogonal vector to point
*/

vec3 normal(vec3 p)
{
  vec3 n;
  float epsilon = 0.01;
  n.x = scene(vec3(p.x + epsilon, p.y, p.z)).sdf - scene(vec3(p.x - epsilon, p.y, p.z)).sdf;
  n.y = scene(vec3(p.x, p.y + epsilon, p.z)).sdf - scene(vec3(p.x, p.y - epsilon, p.z)).sdf;
  n.z = scene(vec3(p.x, p.y, p.z + epsilon)).sdf - scene(vec3(p.x, p.y, p.z - epsilon)).sdf;
  return normalize(n);
}

/*
  @name: trace
  @desc: our main trace routine
      check distances to scene objects
      returns an intersection with data about object and intersection
*/
    
#define MAX_STEPS 256
#define NEAR 0.01
#define FAR 100.0
    
intersection trace(vec3 ro, vec3 rd)
{
  intersection t;

  for (int i = 0; i < MAX_STEPS; i++)
  {
    if (t.dist > FAR) break;

    vec3 p = ro + rd * t.dist;
    sceneObj obj = scene(p);

    if (obj.sdf < NEAR)
    {
      t.isHit = true;
      t.steps = i;
      t.p = p;
      t.obj = obj;
      t.n = normal(p);
      break;
    }

    t.dist += obj.sdf;
  }

  return t;
}

/*
  @name: render
  @desc: calls trace and renders the scene
*/

vec4 render(vec2 fragCoord)
{
  vec2 uv = fragCoord / u_resolution.xy - 0.5;
  uv.x *= u_resolution.x / u_resolution.y;

  vec3 color;

  camera cam;
  cam.origin = vec3(0, 0, 3);
  cam.direction = normalize(vec3(uv, -1));

  intersection t = trace(cam.origin, cam.direction);

  if (t.isHit)
  {
    vec3 lightPos = vec3(0, 1, 1);
    vec3 l = normalize(lightPos - t.p);
    float lambert = max(dot(l, t.n), 0.0);
    color = vec3(t.obj.color * lambert);    
  }

  return vec4(color, 1);
}

/*
  @name: main
  @desc: main entry point, calls render to assigns color out
*/

void main()
{
  vec4 color = render(gl_FragCoord.xy);
  gl_FragColor = color;
}
