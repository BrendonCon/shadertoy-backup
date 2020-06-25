float rect(in vec2 uv, vec2 size, vec2 blur) {
  vec2 halfSize = size * 0.5;
  float h = smoothstep(halfSize.x, halfSize.x - blur.x, abs(uv.x));
  float v = smoothstep(halfSize.y, halfSize.y - blur.y, abs(uv.y));
  return h * v;
}
