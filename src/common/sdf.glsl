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
