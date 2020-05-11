float circle(vec2 uv, float radius, float blur) {
  return smoothstep(radius, radius - blur, length(uv));
}