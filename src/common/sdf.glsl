float sdfSphere(vec3 p, float radius) {
  return length(p) - radius;
}

float sdfBox(vec3 p, vec3 size) {
  return length(max(abs(p) - size, 0.0));
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

float sdfTorus(vec3 p, float r1, float r2) {
  float x = length(p.xz) - r1;
  return length(vec2(x, p.y)) - r2;
}
