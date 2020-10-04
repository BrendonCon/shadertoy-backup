float sdfSphere(vec3 uv, vec4 sphere) {
  return length(uv - sphere.xyz) - sphere.w;
}

float sdfBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);    
}

float sdfPlane(vec3 p, vec4 n, float h) {
  return dot(p, n) + h;
}

float sdfCapsule(vec3 p, vec3 a, vec3 b, float radius) {
  vec3 ap = p - a;
  vec3 ab = b - a;

  float proj = dot(ap, ab) / dot(ab, ab);
  proj = clamp(proj, 0.0, 1.0); 

  vec3 closest = a + proj * ab;

  return length(p - closest) - radius;
}
