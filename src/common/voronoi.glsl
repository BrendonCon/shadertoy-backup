float hash(vec2 p) { 
  return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); 
}

float voronoi(in vec2 p) {
  vec2 n = floor(p);
  vec2 f = fract(p);
  float md = 1.0;
  vec2 m = vec2(0.0);

  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      vec2 g = vec2(i, j);
      vec2 o = vec2(hash(n + g));

      o = 0.5 + 0.5 * sin(5.0 * o);

      vec2 r = g + o - f;
      float d = dot(r, r);

      if (d < md) {
        md = d;
        m = n + g + o;
      }
    }
  }
  
  return max(1.0 - md, 0.1);
}
